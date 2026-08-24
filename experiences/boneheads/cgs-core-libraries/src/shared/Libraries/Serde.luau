-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")

local Serde = {}

function Serde.serializeAndCompress<T>(data: T): string
	local json = HttpService:JSONEncode(data)
	local compressed = EncodingService:CompressBuffer(buffer.fromstring(json), Enum.CompressionAlgorithm.Zstd)
	-- Base64 encoding to support storage in DataStore
	local base64 = EncodingService:Base64Encode(compressed)
	return buffer.tostring(base64)
end

function Serde.decompressAndDeserialize<T>(base64: string): T
	local compressed = EncodingService:Base64Decode(buffer.fromstring(base64))
	local decompressed = EncodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)
	return HttpService:JSONDecode(buffer.tostring(decompressed))
end

return Serde
