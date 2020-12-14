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
    unsafe fn match_child(parent: __m256i, child: __m256i) -> bool {
        // Take the child from the passed parent
        let extracted: __m256i = _mm256_permute4x64_epi64(parent, 0b10_10_10_10);

        // Check: Does the passed child equal the passed parent's child?
        let packed_relationships: __m256i = _mm256_cmpeq_epi64(extracted, child);

        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(packed_relationships);
        relationships[0] == ALLHOT
    }
    unsafe fn match_sibling(lhs: __m256i, sibling: __m256i) -> bool {
        // Take the sibling from the passed lefthand
        let extracted: __m256i = _mm256_permute4x64_epi64(lhs, 0b01_01_01_01);

        // Check: Does the passed sibling equal the passed left side's sibling?
        let packed_relationships: __m256i = _mm256_cmpeq_epi64(extracted, sibling);

        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(packed_relationships);
        relationships[0] == ALLHOT
    }
    unsafe fn match_self(lhs: __m256i, rhs: u64) -> bool {
        // Set everything in a vector to the right hand side
        let broadcasted: __m256i = _mm256_set1_epi64x(rhs as i64);

        // Check: Is anything equal to the right hand we just set?
        let packed_relationships: __m256i = _mm256_cmpeq_epi64(lhs, broadcasted);

        // Extract result of self
        let relationships: [u64; 4] = Tree::unpacked_values(packed_relationships);
        relationships[0] != ALLHOT
    }
    unsafe fn construct_child_or_sibling(&mut self, idx: u64) -> u64 {
        let mut pivot = self.children.get_mut(&idx).unwrap();
        let insertee: &mut __m256i = &mut _mm256_setzero_si256();
        match Tree::get_child(*pivot) {
            0x0000_0000_0000_0000_u64 => {
                // Construct a child
                self.hint_idx += 1;
                std::mem::swap(
                    insertee,
                    &mut _mm256_set_epi64x(
                        idx as i64,
                        IGNORE as i64,
                        IGNORE as i64,
                        self.hint_idx as i64,
                    ),
                );
                *pivot = _mm256_or_si256(
                    *pivot,
                    _mm256_set_epi64x(
                        IGNORE as i64,
                        self.hint_idx as i64,
                        IGNORE as i64,
                        IGNORE as i64,
                    ),
                );
            }
            _ => loop {
                // Construct a sibling
                match Tree::get_sibling(*pivot) {
                    0x0000_0000_0000_0000_u64 => {
                        self.hint_idx += 1;
                        std::mem::swap(
                            insertee,
                            &mut _mm256_set_epi64x(
                                IGNORE as i64,
                                IGNORE as i64,
                                IGNORE as i64,
                                self.hint_idx as i64,
                            ),
                        );
                        *pivot = _mm256_or_si256(
                            *pivot,
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
                        pivot = self.children.get_mut(&next).unwrap();
                        continue;
                    }
                }
            },
        }
        self.children.insert(self.hint_idx, *insertee);
        self.hint_idx
    }
}

rustler::rustler_export_nifs! {
    "Elixir.LdGraphstore.Native",
    [
        ("db_create", 0, db_create),
        ("db_test", 0, db_test)
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

fn db_test<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    unsafe {
        let mut tree = Tree::new();
        assert_eq!(tree.construct_child_or_sibling(1_u64), 2);
        assert_eq!(tree.construct_child_or_sibling(2_u64), 3);
        assert_eq!(tree.construct_child_or_sibling(2_u64), 4);
    }
    Ok(atoms::ok().encode(env))
}
