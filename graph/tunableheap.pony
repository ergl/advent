// Copyright (C) 2016-2019, The Pony Developers
// Copyright (c) 2014-2015, Causality Ltd.
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Code below taken https://github.com/ponylang/ponyc/blob/master/packages/collections/heap.pony

class _HeapEntry[A: Any val] is Comparable[_HeapEntry[A] box]
  let entry: A
  var weight: U64

  new create(entry': A, weight': U64) =>
    entry = entry'
    weight = weight'

  fun lt(that: _HeapEntry[A] box): Bool =>
    weight < that.weight

class TunableHeap[A: Comparable[A] val]
  embed _data: Array[_HeapEntry[A]]

  new create(len: USize = 4) =>
    _data = Array[_HeapEntry[A]](len)

  fun ref clear() =>
    _data.clear()

  fun size(): USize =>
    _data.size()

  fun peek(): this->A ? =>
    _data(0)?.entry

  fun ref push(value: A, weight: U64) =>
    _data.push(_HeapEntry[A].create(value, weight))
    _shift_up(size() - 1)

  fun ref update(value: A, new_weight: U64) =>
    try
      var idx: USize = 0
      while idx < _data.size() do
        if _data(idx)?.entry == value then
          break
        end
        idx = idx + 1
      end
      _data.delete(idx)?
      push(value, new_weight)
    end

  fun ref pop(): A^ ? =>
    let n = size() - 1
    _data.swap_elements(0, n)?
    _shift_down(0, n)
    _data.pop()?.entry

  fun ref _shift_up(n: USize) =>
    var idx = n
    try
      while true do
        let parent_idx = (idx - 1) / 2
        if (parent_idx == idx) or (_data(idx)? >= _data(parent_idx)?) then
          break
        end
          _data.swap_elements(parent_idx, idx)?
          idx = parent_idx
      end
    end

  fun ref _shift_down(start: USize, n: USize): Bool =>
    var idx = start
    try
      while true do
        var left = (2 * idx) + 1
        if (left >= n) or (left < 0) then
          break
        end
        let right = left + 1
        if (right < n) and (_data(right)? < _data(left)?) then
          left = right
        end
        if (_data(left)? >= _data(idx)?) then
          break
        end
        _data.swap_elements(idx, left)?
        idx = left
      end
    end
    idx > start
