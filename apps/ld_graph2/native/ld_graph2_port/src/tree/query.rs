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
use crate::tree::Valid;
use serde::{Deserialize, Serialize};

// Serde types can not be usized and I feel more comfortable with an explicit
// type anyhow. Let's do it like this then.
const GET: u16 = 0;
const PUT: u16 = 1;
const DEL: u16 = 2;

#[repr(u16)]
pub enum QueryType {
    Get = GET,
    Put = PUT,
    Del = DEL,
}

impl QueryType {
    pub fn from_u16(val: u16) -> QueryType {
        match val {
            GET => QueryType::Get,
            PUT => QueryType::Put,
            DEL => QueryType::Del
        }
    }
}

#[derive(Deserialize, Serialize)]
pub struct Query<T: Valid> {
    // What type of query
    pub qtype: u16,
    
    // The queried value
    pub identifier: T,
    
    // The depth of the query
    // Negative: query parents
    // Zero: query only this
    // Positive: query children
    pub depth: i16
}
