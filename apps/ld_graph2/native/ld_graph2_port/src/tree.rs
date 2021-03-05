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
use crate::tree::{query::{Query, QueryType}, reply::Reply, node::Node};
use std::collections::HashMap;

pub mod node;
pub mod query;
pub mod reply;

// ============================================================================
//  Validity and implementations thereof
// ============================================================================
pub trait Valid {
    fn new_rootid() -> Self;
    fn new_ignore() -> Self;
}
impl Valid for u8 {
    fn new_rootid() -> u8 {
        1_u8
    }
    fn new_ignore() -> u8 {
        0_u8
    }
}
impl Valid for u16 {
    fn new_rootid() -> u16 {
        1_u16
    }
    fn new_ignore() -> u16 {
        0_u16
    }
}
impl Valid for u32 {
    fn new_rootid() -> u32 {
        1_u32
    }
    fn new_ignore() -> u32 {
        0_u32
    }
}
impl Valid for u64 {
    fn new_rootid() -> u64 {
        1_u64
    }
    fn new_ignore() -> u64 {
        0_u64
    }
}

pub struct Store<T: Valid> {
    pub cache: HashMap<T, Node<T>>,
    highest: T,
}

// ============================================================================
//  Tree node implementations
// ============================================================================
#[repr(u16)]
pub enum StoreError {
    // The object to shallow delete has children
    // It is not possible to shallow delete this object
    HasChildren = 1,
    
    // The object does not exist
    DoesNotExist = 2,
    
    // Ran out of space
    OutOfSpace = 3,
    
    // This query can only be mutable
    MutableQuery = 4,
}
impl Store<u32> {
    pub fn new() -> Store<u32> {
        Store::<u32> {
            cache: HashMap::new(),
            highest: u32::new_rootid(),
        }
    }
    pub fn query(&self, query: Query<u32>) -> Result<Reply<u32>, StoreError> {
        match QueryType::from_u16(query.qtype) {
            QueryType::Get => {
                
            },
            QueryType::Put => { Err(StoreError::MutableQuery) }
            QueryType::Del => { Err(StoreError::MutableQuery) }
        }
    }
    pub fn query_mut(&mut self, query: Query<u32>) -> Result<Reply<u32>, StoreError> {}
}
