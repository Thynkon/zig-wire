const std = @import("std");
const pcap = @cImport({
    @cInclude("pcap.h");
    @cInclude("pcap/pcap.h");
});
const builtin = @import("builtin");
const utils = @import("utils.zig");
const native_endian = builtin.target.cpu.arch.endian();

const PcapWrapperError = error{
    UnintializedError,
    PcapError,
};

const IPv4Flags = packed struct(u3) {
    reserved: bool,
    df: bool,
    mf: bool,
};

const IPv4Header = struct {
    version: u4,
    // nb of bytes - with * 4
    headerLength: u6,
    dscp: u6,
    ecn: u2,
    totalLength: u16,
    id: u16,
    flags: u3,
    fragmentationOffset: u13,
    ttl: u8,
    protocol: u8,
    checksum: u16,
    sourceAddress: u32,
    destinationAddress: u32,
    // options: []const u8,
    // TODO: implement options/padding
};

pub const IPv4Packet = struct {
    header: IPv4Header,
    payload: []const u8,

    pub fn print(self: IPv4Packet, allocator: std.mem.Allocator) !void {
        const fmtSourceAddress = try utils.ipAddressToString(allocator, self.header.sourceAddress);
        defer allocator.free(fmtSourceAddress);

        const fmtDestinationAddress = try utils.ipAddressToString(allocator, self.header.destinationAddress);
        defer allocator.free(fmtDestinationAddress);

        std.debug.print("IPv4 Header:\n", .{});
        std.debug.print("  version: {d}\n", .{self.header.version});
        std.debug.print("  headerLength: {d}\n", .{self.header.headerLength});
        std.debug.print("  dscp: {d}\n", .{self.header.dscp});
        std.debug.print("  ecn: {d}\n", .{self.header.ecn});
        std.debug.print("  total_length: {d}\n", .{self.header.totalLength});
        std.debug.print("  id: {d}\n", .{self.header.id});
        std.debug.print("  flags: {d}\n", .{self.header.flags});
        std.debug.print("  fragmentation_offset: {d}\n", .{self.header.fragmentationOffset});
        std.debug.print("  ttl: {d}\n", .{self.header.ttl});
        std.debug.print("  protocol: {d}\n", .{self.header.protocol});
        std.debug.print("  checksum: 0x{x}\n", .{self.header.checksum});
        std.debug.print("  sourceAddress: {s}\n", .{fmtSourceAddress});
        std.debug.print("  destinationAddress: {s}\n", .{fmtDestinationAddress});
    }
};

pub fn readFromBytes(bytes: []const u8) IPv4Packet {
    var packet: IPv4Packet = undefined;
    var header: IPv4Header = undefined;

    if (native_endian == .little) {
        header.version = @intCast(bytes[0] >> 4);
        header.headerLength = @intCast(bytes[0] & 0xF);
        header.headerLength *= 4;
    } else {
        header.version = @intCast(bytes[0] >> 4);
        header.headerLength = @intCast(bytes[1] & 0xF);
        header.headerLength *= 4;
    }

    header.dscp = @intCast(bytes[1] & 0x6);
    header.ecn = @intCast(bytes[1] >> 6);
    // bits already in right order, so pass "big-endian" to do nothing
    header.totalLength = std.mem.readInt(u16, bytes[2..4], .big);
    header.id = std.mem.readInt(u16, bytes[4..6], .big);
    header.flags = @truncate(bytes[6]);
    // header.fragmentation_offset = bytes[6..8] & 0xFFF4;
    header.fragmentationOffset = @truncate(std.mem.readInt(u16, bytes[2..4], .big) & 0xFFF4);
    // header.fragmentationOffset = 0;
    header.ttl = bytes[8];
    header.protocol = bytes[9];
    header.checksum = std.mem.readInt(u16, bytes[10..12], .big);
    header.sourceAddress = std.mem.readInt(u32, bytes[12..16], .big);
    header.destinationAddress = std.mem.readInt(u32, bytes[16..20], .big);
    // TODO: implement options
    // header.options = bytes[20..header.total_length];

    packet.header = header;
    packet.payload = bytes[header.headerLength..header.totalLength];

    return packet;
}
