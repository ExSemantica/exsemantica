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
use crate::tree::{Valid, node::Node};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
pub struct Reply<T: Valid> {
    pub content: Vec<Node<T>>
}

impl Reply<u8> {
    pub fn new() -> Reply<u8> {
        Reply::<u8> {
            content: vec![]
        }
    }
}
impl Reply<u16> {
    pub fn new() -> Reply<u16> {
        Reply::<u16> {
            content: vec![]
        }
    }
}
impl Reply<u32> {
    pub fn new() -> Reply<u32> {
        Reply::<u32> {
            content: vec![]
        }
    }
}
impl Reply<u64> {
    pub fn new() -> Reply<u64> {
        Reply::<u64> {
            content: vec![]
        }
    }
}
