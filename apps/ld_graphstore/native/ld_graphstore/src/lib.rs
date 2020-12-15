// Copyright 2020 Roland Metivier
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
use rustler::{Encoder, Env, Error, ResourceArc, Term};
use std::collections::HashMap;
use std::sync::RwLock;

static IGNORE: u64 = 0x0000_0000_0000_0000;
static ROOTID: u64 = 0x0000_0000_0000_0001;
static ALLHOT: u64 = 0xFFFF_FFFF_FFFF_FFFF;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

#[derive(Clone)]
struct Tree {
    hint_idx: u64,
    children: HashMap<u64, __m256i>,
}

struct TreeResource {
    rw: RwLock<Tree>,
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
    unsafe fn unpacked_values(packed: __m256i) -> [u64; 4] {
        let mut extracted: [u64; 4] = [ALLHOT, ALLHOT, ALLHOT, ALLHOT];
        _mm256_maskstore_epi64(
            extracted.as_mut_ptr() as *mut i64,
            _mm256_set1_epi64x(ALLHOT as i64),
            packed,
        );
        extracted
    }
    unsafe fn get_parent(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[3]
    }
    unsafe fn get_child(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[2]
    }
    unsafe fn get_sibling(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[1]
    }
    unsafe fn get_self(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[0]
    }
    unsafe fn construct_child(&mut self, idx: u64) -> Result<u64, &'static str> {
        assert_ne!(idx, 0);
        match Tree::get_child(self.children[&idx]) {
            0x0000_0000_0000_0000_u64 => {
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
                Ok(self.hint_idx)
            }
            _ => Err("tree node already has child, try adding it as a sibling"),
        }
    }
    unsafe fn construct_sibling(&mut self, idx: u64) -> u64 {
        assert_ne!(idx, 0);
        let mut pivot = self.children[&idx];
        loop {
            // Construct a sibling
            match Tree::get_sibling(pivot) {
                0x0000_0000_0000_0000_u64 => {
                    self.hint_idx += 1;
                    // NOTE: The parent of a sibling will be its last sibling
                    pivot = _mm256_or_si256(
                        pivot,
                        _mm256_set_epi64x(
                            IGNORE as i64,
                            IGNORE as i64,
                            self.hint_idx as i64,
                            IGNORE as i64,
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
        self.hint_idx
    }
    unsafe fn delete_sibling(&mut self, idx: u64) -> bool {
        assert_ne!(idx, 0);
        match Tree::get_sibling(self.children[&idx]) {
            0x0000_0000_0000_0000_u64 => false,
            sibling => {
                match Tree::get_sibling(self.children[&sibling]) {
                    0x0000_0000_0000_0000_u64 => {
                        self.children.insert(
                            idx,
                            _mm256_xor_si256(
                                self.children[&idx],
                                _mm256_set_epi64x(
                                    IGNORE as i64,
                                    IGNORE as i64,
                                    sibling as i64,
                                    IGNORE as i64,
                                ),
                            ),
                        );
                    }
                    grandsibling => {
                        self.children.insert(
                            idx,
                            _mm256_or_si256(
                                _mm256_xor_si256(
                                    self.children[&idx],
                                    _mm256_set_epi64x(
                                        IGNORE as i64,
                                        IGNORE as i64,
                                        sibling as i64,
                                        IGNORE as i64,
                                    ),
                                ),
                                _mm256_set_epi64x(
                                    IGNORE as i64,
                                    IGNORE as i64,
                                    grandsibling as i64,
                                    IGNORE as i64,
                                ),
                            ),
                        );
                        self.children.insert(
                            grandsibling,
                            _mm256_or_si256(
                                _mm256_xor_si256(
                                    self.children[&idx],
                                    _mm256_set_epi64x(
                                        sibling as i64,
                                        IGNORE as i64,
                                        IGNORE as i64,
                                        IGNORE as i64,
                                    ),
                                ),
                                _mm256_set_epi64x(
                                    idx as i64,
                                    IGNORE as i64,
                                    IGNORE as i64,
                                    IGNORE as i64,
                                ),
                            ),
                        );
                    }
                }
                self.children.remove(&sibling);
                true
            }
        }
    }
    unsafe fn delete_child(&mut self, idx: u64) -> bool {
        assert_ne!(idx, 0);
        match Tree::get_child(self.children[&idx]) {
            0x0000_0000_0000_0000_u64 => false,
            child => {
                // Get grandchild
                match Tree::get_child(self.children[&child]) {
                    0x0000_0000_0000_0000_u64 => {
                        // None
                        self.children.insert(
                            idx,
                            _mm256_xor_si256(
                                self.children[&idx],
                                _mm256_set_epi64x(
                                    IGNORE as i64,
                                    child as i64,
                                    IGNORE as i64,
                                    IGNORE as i64,
                                ),
                            ),
                        );
                    }
                    grandchild => {
                        // TODO: Optimize the below routine to adequately utilize SIMD and Rust features
                        // Perhaps a self.delete_all_siblings call to implement later :)
                        while self.delete_sibling(grandchild) {}
                        self.delete_child(grandchild);
                    }
                };
                self.children.remove(&child);
                true
            }
        }
    }
}

rustler::rustler_export_nifs! {
    "Elixir.LdGraphstore.Native",
    [
        ("db_create", 0, db_create),
        ("db_test", 1, db_test)
    ],
    Some(on_load)
}

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource_struct_init!(TreeResource, env);
    true
}

fn db_create<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    unsafe {
        let resource = ResourceArc::new(TreeResource {
            rw: RwLock::new(Tree::new()),
        });
        Ok((atoms::ok(), resource).encode(env))
    }
}

fn db_test<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    unsafe {
        let mut tree = Tree::new();

        println!("Logical testing...");
        assert_eq!(tree.construct_child(1_u64).unwrap(), 2);
        assert_eq!(tree.construct_child(2_u64).unwrap(), 3);
        assert_eq!(tree.construct_sibling(2_u64), 4);
        tree.delete_child(2_u64);
        let stress: u64 = args[0].decode()?;
        let mut interval = 0_u64;
        println!("Stress testing... {:?}", stress);
        for _ in 0..stress {
            interval = tree.construct_sibling(4_u64);
        }
        tree.delete_child(2_u64);
        println!("Passed sibling construction/destruction without catching fire (at {})", interval);
        for _ in 0..stress {
            interval = tree.construct_child(interval).expect("test failed");
        }
        println!("Passed child-sibling construction without catching fire (at {})", interval);
    }
    Ok(atoms::ok().encode(env))
}
