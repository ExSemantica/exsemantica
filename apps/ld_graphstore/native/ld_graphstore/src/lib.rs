// Copyright 2020-2021 Roland Metivier
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};
use std::collections::HashMap;
use std::sync::RwLock;

static IGNORE: u64 = 0x0000_0000_0000_0000;
static ROOTID: u64 = 0x0000_0000_0000_0001;
static ALLHOT: u64 = 0xFFFF_FFFF_FFFF_FFFF;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
        atom noval;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

struct Tree {
    hint_idx: u64,
    children: HashMap<u64, __m256i>,
}

struct TreeResource {
    rw: RwLock<Tree>,
}

#[derive(NifStruct)]
#[module = "LdGraphstore.Native.TreeNode"]
struct TreeNode {
    parent: Option<u64>,
    child: Option<u64>,
    sibling: Option<u64>,
    this: u64,
}

impl Tree {
    unsafe fn new() -> Tree {
        let mut tree = Tree {
            hint_idx: ROOTID,
            children: HashMap::new(),
        };
        tree.children.insert(
            1,
            _mm256_set_epi64x(
                IGNORE as i64, // Parent  (val[3])
                IGNORE as i64, // Child   (val[2])
                IGNORE as i64, // Sibling (val[1])
                ROOTID as i64, // Self    (val[0])
            ),
        );
        tree
    }
    fn wrap(val: u64) -> Option<u64> {
        if val == IGNORE {
            None
        } else {
            Some(val)
        }
    }
    unsafe fn unpacked_values(packed: __m256i) -> [u64; 4] {
        let mut extracted: [u64; 4] = [ALLHOT, ALLHOT, ALLHOT, ALLHOT];
        _mm256_maskstore_epi64(
            extracted.as_mut_ptr() as *mut i64,
            _mm256_set1_epi64x(ALLHOT as i64),
            packed,
        );
        extracted
    }
    unsafe fn get_parent(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[3])
    }
    unsafe fn get_child(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[2])
    }
    unsafe fn get_sibling(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[1])
    }
    unsafe fn get_self(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[0]
    }
    unsafe fn construct(&mut self, idx: u64) -> u64 {
        assert_ne!(idx, 0);
        match Tree::get_child(self.children[&idx]).unwrap_or(IGNORE) {
            0x0000_0000_0000_0000_u64 => {
                // Construct a child
                self.hint_idx += 1;

                self.children.insert(
                    idx,
                    _mm256_or_si256(
                        self.children[&idx],
                        _mm256_set_epi64x(
                            IGNORE as i64,
                            self.hint_idx as i64,
                            IGNORE as i64,
                            IGNORE as i64,
                        ),
                    ),
                );
                self.children.insert(
                    self.hint_idx,
                    _mm256_set_epi64x(
                        idx as i64,
                        IGNORE as i64,
                        IGNORE as i64,
                        self.hint_idx as i64,
                    ),
                );
                self.hint_idx
            }
            _ => {
                // Construct a sibling
                let mut pivot = self.children[&idx];
                loop {
                    match Tree::get_sibling(pivot).unwrap_or(IGNORE) {
                        0x0000_0000_0000_0000_u64 => {
                            self.hint_idx += 1;
                            // NOTE: The parent of a sibling will be its last sibling
                            self.children.insert(
                                Tree::get_self(pivot),
                                _mm256_or_si256(
                                    pivot,
                                    _mm256_set_epi64x(
                                        IGNORE as i64,
                                        IGNORE as i64,
                                        self.hint_idx as i64,
                                        IGNORE as i64,
                                    ),
                                ),
                            );
                            // Finally insert the sibling
                            self.children.insert(
                                self.hint_idx,
                                _mm256_set_epi64x(
                                    Tree::get_self(pivot) as i64,
                                    IGNORE as i64,
                                    IGNORE as i64,
                                    self.hint_idx as i64,
                                ),
                            );
                            break;
                        }
                        next => {
                            pivot = self.children[&next];
                            continue;
                        }
                    }
                }
                self.hint_idx
            }
        }
    }
    unsafe fn collect(&mut self) {
        let zeroes = _mm256_setzero_si256();
        self.children.retain(|&k, &mut v| {
            // If parent is equal to zero then GC
            if let Some(_) = Tree::get_parent(_mm256_cmpeq_epi64(v, zeroes)) {
                k == ROOTID
            } else {
                true
            }
        });
    }
    unsafe fn remove(&mut self, idx: u64) {
        assert_ne!(idx, 0);
        assert_ne!(idx, 1);
        let zeroes = _mm256_setzero_si256();
        match Tree::unpacked_values(self.children[&idx]) {
            [obj, 0_u64, 0_u64, 0_u64] => {
                self.children.insert(obj, zeroes);
            }
            [obj, 0_u64, 0_u64, parent] => {
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
            [obj, sibling, 0_u64, parent] => {
                // Since parent(s) are zeroed, we will automatically GC it later
                let mut next = Tree::wrap(sibling);
                while let Some(next_unwrapped) = next {
                    next = Tree::get_sibling(self.children[&next_unwrapped]);
                    self.children.insert(next_unwrapped, zeroes);
                }
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
            [obj, sibling, child, parent] => {
                self.remove(sibling);
                self.remove(child);
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
        }
    }
}

rustler::rustler_export_nifs! {
    "Elixir.LdGraphstore.Native",
    [
        ("db_create", 0, db_create),
        ("db_gc", 1, db_gc),
        ("db_test", 1, db_test),
        ("db_get", 2, db_get),
        ("db_put", 2, db_put),
        ("db_del", 2, db_del),
    ],
    Some(on_load)
}

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource_struct_init!(TreeResource, env);
    true
}

fn db_create<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource = unsafe {
        ResourceArc::new(TreeResource {
            rw: RwLock::new(Tree::new()),
        })
    };
    Ok((atoms::ok(), resource).encode(env))
}

fn db_gc<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    unsafe {
        resource
            .rw
            .write()
            .expect("can't lock for writing")
            .collect()
    };
    Ok((atoms::ok()).encode(env))
}

fn db_get<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let item = resource.rw.read().expect("can't lock for reading");
    let idx: u64 = args[1].decode()?;
    let exists = {
        if item.children.contains_key(&idx) {
            0_u64 != unsafe { Tree::get_self(item.children[&idx]) }
        } else {
            false
        }
    };
    if exists {
        let vals = unsafe { Tree::unpacked_values(item.children[&idx]) };
        Ok((
            atoms::ok(),
            TreeNode {
                parent: Tree::wrap(vals[3]),
                child: Tree::wrap(vals[2]),
                sibling: Tree::wrap(vals[1]),
                this: vals[0],
            },
        )
            .encode(env))
    } else {
        Ok((atoms::error(), atoms::noval()).encode(env))
    }
}

fn db_put<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let mut item = resource.rw.write().expect("can't lock for writing");
    let idx: u64 = args[1].decode()?;
    let exists = {
        if item.children.contains_key(&idx) {
            0_u64 != unsafe { Tree::get_self(item.children[&idx]) }
        } else {
            false
        }
    };
    if exists {
        let child_idx: u64 = unsafe { item.construct(idx) };
        Ok((atoms::ok(), child_idx).encode(env))
    } else {
        Ok((atoms::error(), atoms::noval()).encode(env))
    }
}

fn db_del<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let mut item = resource.rw.write().expect("can't lock for writing");
    let idx: u64 = args[1].decode()?;

    let exists = {
        if item.children.contains_key(&idx) {
            0_u64 != unsafe { Tree::get_self(item.children[&idx]) }
        } else {
            false
        }
    };
    if exists {
        unsafe { item.remove(idx) };
        Ok(atoms::ok().encode(env))
    } else {
        Ok((atoms::error(), atoms::noval()).encode(env))
    }
}

fn db_test<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    unsafe {
        let mut tree = Tree::new();

        println!("Logical testing...\r");
        assert_eq!(tree.construct(1_u64), 2);
        assert_eq!(tree.construct(2_u64), 3);
        assert_eq!(tree.construct(2_u64), 4);
        let stress: u64 = args[0].decode()?;
        let mut interval = 4_u64;
        println!("Stress testing... {:?}\r", stress);
        for _ in 0..stress {
            interval = tree.construct(4_u64);
        }
        println!(
            "Passed sibling construction/destruction without catching fire (at {})\r",
            interval
        );
        for _ in 0..stress {
            interval = tree.construct(interval);
        }
        println!(
            "Passed child-sibling construction without catching fire (at {})\r",
            interval
        );
        tree.remove(2_u64);
        println!("Passed removal of all elements\r");
        tree.collect();
        println!("GC all good\r");
    }
    Ok(atoms::ok().encode(env))
}
