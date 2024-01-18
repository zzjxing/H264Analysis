package bitstream

import (
	"errors"
)

const BitNum = 8

func CreateBitstream(data []uint8, size int) BitStream {
	var stream BitStream
	stream.Init(data, size)
	return stream
}

type BitStream struct {
	rbsp  []byte
	size  int
	bits  int
	error error
}

func (stream *BitStream) Init(rbsp []byte, bytes int) {
	stream.rbsp = rbsp
	stream.size = bytes
	stream.bits = 0
	stream.error = nil
}

func (stream *BitStream) Error() error {
	return stream.error
}

func (stream *BitStream) MoveNextBit() {
	stream.bits++
	if stream.bits%BitNum != 0 {
		return
	}
	offset := stream.bits / BitNum
	// check 0x00 0x00 0x03
	if offset < stream.size && offset > 1 &&
		0x03 == stream.rbsp[offset] &&
		0x00 == stream.rbsp[offset-1] &&
		0x00 == stream.rbsp[offset-2] {
		stream.bits += BitNum // skip 0x03
	}
}

func (stream *BitStream) GetOffset() int {
	return stream.bits
}

func (stream *BitStream) SetOffset(bits int) {
	if bits > stream.size*BitNum {
		stream.error = errors.New("offset exceeds the size of the BitStream")
		return
	}

	stream.bits = bits
}

func (stream *BitStream) NextBit() int {
	if stream.bits >= stream.size*BitNum {
		stream.error = errors.New("attempt to read beyond the end of the BitStream")
		return 0
	}

	bit := (stream.rbsp[stream.bits/BitNum] >> (BitNum - 1 - (stream.bits % BitNum))) & 0x01
	return int(bit)
}

func (stream *BitStream) NextBits(bits int) int {
	s := *stream
	return s.ReadBits(bits)
}

func (stream *BitStream) ReadBit() int {
	bit := stream.NextBit()
	assert(bit == 0 || bit == 1, "Bit value must be 0 or 1.")
	stream.MoveNextBit()
	return bit
}

func (stream *BitStream) ReadBits(num int) int {
	var value int
	assert(stream != nil && num >= 0 && num <= 64, "")
	for i := 0; i < num && stream.Error() == nil; i++ {
		bit := stream.ReadBit()
		value = (value << 1) | bit
	}
	return value
}

func (stream *BitStream) ReadUE() int {
	var bit int
	leadingZeroBits := -1

	for bit == 0 && stream.error == nil {
		leadingZeroBits++
		bit = stream.ReadBit()
	}

	value := 0
	if leadingZeroBits > 0 {
		value = stream.ReadBits(leadingZeroBits)
	}
	return (1 << leadingZeroBits) - 1 + value
}

func (stream *BitStream) ReadSE() int {
	v := stream.ReadUE()
	return (v + 1) / 2 * ((v&1)*2 - 1)
}

func (stream *BitStream) ReadME(chromaFormatIDC, codedBlockPattern int) int {
	intra := []int{0, 16, 1, 2, 4, 8, 32, 3, 5, 10, 12, 15, 47, 7, 11, 13, 14, 6, 9, 31, 35, 37, 42, 44, 33, 34, 36, 40, 39, 43, 45, 46, 17, 18, 20, 24, 19, 21, 26, 28, 23, 27, 29, 30, 22, 25, 38, 41}
	intra4x48x8 := []int{47, 31, 15, 0, 23, 27, 29, 30, 7, 11, 13, 14, 39, 43, 45, 46, 16, 3, 5, 10, 12, 19, 21, 26, 28, 35, 37, 42, 44, 1, 2, 4, 8, 17, 18, 20, 24, 6, 9, 22, 25, 32, 33, 34, 36, 40, 38, 41}
	chromaIntra := []int{15, 0, 7, 11, 13, 14, 3, 5, 10, 12, 1, 2, 4, 8, 6, 9}
	chromaintra4x48x8 := []int{0, 1, 2, 4, 8, 3, 5, 10, 12, 15, 7, 11, 13, 14, 6, 9}

	var v int
	if chromaFormatIDC != 0 {
		assert(v >= 0 && v < 48, "Invalid value for chromaFormatIDC")
		if codedBlockPattern != 0 {
			v = intra[v]
		} else {
			v = intra4x48x8[v]
		}
	} else {
		assert(v >= 0 && v < 16, "Invalid value for chromaFormatIDC")
		if codedBlockPattern != 0 {
			v = chromaIntra[v]
		} else {
			v = chromaintra4x48x8[v]
		}
	}
	return v
}

func (stream *BitStream) ReadTE() int {
	v := stream.ReadUE()
	if v != 1 {
		return v
	}
	if stream.ReadBit() != 0 {
		return 0
	}
	return 1
}

func assert(condition bool, message string) {
	if !condition {
		panic(message)
	}
}
