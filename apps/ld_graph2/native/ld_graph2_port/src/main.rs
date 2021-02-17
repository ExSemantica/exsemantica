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
mod tree;
type TreeQu = tree::query::Query;
type TreeRe = tree::reply::Reply<u32>;

fn main() {
    use erlang_port::{PortReceive, PortSend};

    let mut port = unsafe {
        use erlang_port::PacketSize;
        erlang_port::nouse_stdio(PacketSize::Four)
    };

    println!("Hello, world!");

    for inp in port.receiver.iter::<TreeQu>() {
        let input: TreeQu = inp;
        port.sender
            .reply::<Result<TreeRe, TreeRe>, TreeRe, TreeRe>(Ok(TreeRe::from()))
    }
}
