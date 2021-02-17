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
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub mod query;
pub mod reply;

pub trait Valid {
    pub fn new_rootid() -> Self;
    pub fn new_ignore() -> Self;
}

impl Valid for u8 {}
impl Valid for u16 {}
impl Valid for u32 {}
impl Valid for u64 {}

#[derive(Deserialize, Serialize)]
pub struct Node<T: Valid> {
    pub idx: T,
    pub child: T,
    pub parent: T,
    pub sibling: T
}

pub struct Store<T: Valid> {
    pub cache: HashMap<T, Node<T>>,
    highest: T
}

impl Store<T> {
    pub fn new() -> Store<T> {
        Store
    }
}
