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

#[derive(Deserialize, Serialize)]
pub struct Reply<T: crate::tree::Valid> {
    pub idx: T,
    pub child: T,
    pub parent: T,
    pub sibling: T
}

// u8 not implemented yet
// u16 not implemented yet
impl Reply<u32> {
    pub fn from() -> Reply<u32> {
        Reply::<u32> {
            idx: 0_u32,
            child: 0_u32,
            parent: 0_u32,
            sibling: 0_u32
        }
    }
}
// u64 not implemented yet
