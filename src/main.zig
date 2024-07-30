const std = @import("std");
const pcap_wrapper = @import("./pcap_wrapper.zig");
const device = @import("./device.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const ipv4_packet = @import("packets/ipv4.zig");
const ethernet_frame = @import("frames/ethernet.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    // try device.capture(allocator, "wlp0s20f3", "port 80");

    // 146
    const request = [_]u8{
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x08, 0x00, 0x45, 0x00,
        0x00, 0x7D, 0xB2, 0xEF, 0x40, 0x00, 0x40, 0x06, 0x7C, 0xEA, 0xC0, 0xA8, 0x01, 0xF0, 0x8E, 0xFA,
        0xB9, 0x0E, 0xED, 0xEC, 0x00, 0x50, 0x74, 0x83, 0x2D, 0x5E, 0x9C, 0x63, 0xCB, 0x49, 0x80, 0x18,
        0x01, 0xF6, 0x0B, 0x11, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0A, 0xFC, 0x5B, 0xA9, 0x72, 0x79, 0xD0,
        0x16, 0xB3, 0x47, 0x45, 0x54, 0x42, 0x02, 0xF2, 0x48, 0x54, 0x54, 0x50, 0x2F, 0x31, 0x2E, 0x31,
        0x0D, 0x0A, 0x48, 0x6F, 0x73, 0x74, 0x3A, 0x20, 0x67, 0x6F, 0x6F, 0x67, 0x6C, 0x65, 0x2E, 0x63,
        0x6F, 0x6D, 0x0D, 0x0A, 0x55, 0x73, 0x65, 0x72, 0x2D, 0x41, 0x67, 0x65, 0x6E, 0x74, 0x3A, 0x20,
        0x63, 0x75, 0x72, 0x6C, 0x2F, 0x38, 0x2E, 0x39, 0x2E, 0x30, 0x0D, 0x0A, 0x41, 0x63, 0x63, 0x65,
        0x70, 0x74, 0x3A, 0x20, 0x2A, 0x2F, 0x2A, 0x0D, 0x0A, 0x0D, 0x0A,
    };
    // 488
    const response = [_]u8{
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x08, 0x00, 0x45, 0x00,
        0x03, 0x39, 0x14, 0x0c, 0x00, 0x00, 0x3c, 0x06, 0x5d, 0x12, 0x8e, 0xfa, 0xb9, 0x0e, 0xc0, 0xa8,
        0x01, 0xf0, 0x00, 0x50, 0xed, 0xec, 0x9c, 0x63, 0xcb, 0x49, 0x74, 0x83, 0x2d, 0xa7, 0x80, 0x18,
        0x01, 0x00, 0x51, 0x40, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a, 0x79, 0xd0, 0x17, 0xc9, 0xfc, 0x5b,
        0xa9, 0x72, 0x48, 0x54, 0x54, 0x50, 0x2f, 0x31, 0x2e, 0x31, 0x20, 0x33, 0x30, 0x31, 0x20, 0x4d,
        0x6f, 0x76, 0x65, 0x64, 0x20, 0x50, 0x65, 0x72, 0x6d, 0x61, 0x6e, 0x65, 0x6e, 0x74, 0x6c, 0x79,
        0x0d, 0x0a, 0x4c, 0x6f, 0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x3a, 0x20, 0x68, 0x74, 0x74, 0x70,
        0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x63, 0x6f,
        0x6d, 0x2f, 0x0d, 0x0a, 0x43, 0x6f, 0x6e, 0x74, 0x65, 0x6e, 0x74, 0x2d, 0x54, 0x79, 0x70, 0x65,
        0x3a, 0x20, 0x74, 0x65, 0x78, 0x74, 0x2f, 0x68, 0x74, 0x6d, 0x6c, 0x3b, 0x20, 0x63, 0x68, 0x61,
        0x72, 0x73, 0x65, 0x74, 0x3d, 0x55, 0x54, 0x46, 0x2d, 0x38, 0x0d, 0x0a, 0x43, 0x6f, 0x6e, 0x74,
        0x65, 0x6e, 0x74, 0x2d, 0x53, 0x65, 0x63, 0x75, 0x72, 0x69, 0x74, 0x79, 0x2d, 0x50, 0x6f, 0x6c,
        0x69, 0x63, 0x79, 0x2d, 0x52, 0x65, 0x70, 0x6f, 0x72, 0x74, 0x2d, 0x4f, 0x6e, 0x6c, 0x79, 0x3a,
        0x20, 0x6f, 0x62, 0x6a, 0x65, 0x63, 0x74, 0x2d, 0x73, 0x72, 0x63, 0x20, 0x27, 0x6e, 0x6f, 0x6e,
        0x65, 0x27, 0x3b, 0x62, 0x61, 0x73, 0x65, 0x2d, 0x75, 0x72, 0x69, 0x20, 0x27, 0x73, 0x65, 0x6c,
        0x66, 0x27, 0x3b, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74, 0x2d, 0x73, 0x72, 0x63, 0x20, 0x27, 0x6e,
        0x6f, 0x6e, 0x63, 0x65, 0x2d, 0x4f, 0x2d, 0x4a, 0x6a, 0x65, 0x62, 0x4f, 0x34, 0x6e, 0x39, 0x69,
        0x5a, 0x71, 0x31, 0x36, 0x7a, 0x37, 0x6a, 0x43, 0x70, 0x30, 0x77, 0x27, 0x20, 0x27, 0x73, 0x74,
        0x72, 0x69, 0x63, 0x74, 0x2d, 0x64, 0x79, 0x6e, 0x61, 0x6d, 0x69, 0x63, 0x27, 0x20, 0x27, 0x72,
        0x65, 0x70, 0x6f, 0x72, 0x74, 0x2d, 0x73, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x27, 0x20, 0x27, 0x75,
        0x6e, 0x73, 0x61, 0x66, 0x65, 0x2d, 0x65, 0x76, 0x61, 0x6c, 0x27, 0x20, 0x27, 0x75, 0x6e, 0x73,
        0x61, 0x66, 0x65, 0x2d, 0x69, 0x6e, 0x6c, 0x69, 0x6e, 0x65, 0x27, 0x20, 0x68, 0x74, 0x74, 0x70,
        0x73, 0x3a, 0x20, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x3b, 0x72, 0x65, 0x70, 0x6f, 0x72, 0x74, 0x2d,
        0x75, 0x72, 0x69, 0x20, 0x68, 0x74, 0x74, 0x70, 0x73, 0x3a, 0x2f, 0x2f, 0x63, 0x73, 0x70, 0x2e,
        0x77, 0x69, 0x74, 0x68, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x63,
        0x73, 0x70, 0x2f, 0x67, 0x77, 0x73, 0x2f, 0x6f, 0x74, 0x68, 0x65, 0x72, 0x2d, 0x68, 0x70, 0x0d,
        0x0a, 0x44, 0x61, 0x74, 0x65, 0x3a, 0x20, 0x4d, 0x6f, 0x6e, 0x2c, 0x20, 0x32, 0x39, 0x20, 0x4a,
        0x75, 0x6c, 0x20, 0x32, 0x30, 0x32, 0x34, 0x20, 0x31, 0x38, 0x3a, 0x35, 0x39, 0x3a, 0x33, 0x38,
        0x20, 0x47, 0x4d, 0x54, 0x0d, 0x0a, 0x45, 0x78, 0x70, 0x69, 0x72, 0x65, 0x73, 0x3a, 0x20, 0x57,
        0x65, 0x64, 0x2c, 0x20, 0x32, 0x38, 0x20, 0x41, 0x75, 0x67, 0x20, 0x32, 0x30, 0x32, 0x34, 0x20,
        0x31, 0x38, 0x3a, 0x35, 0x39, 0x3a, 0x33, 0x38, 0x20, 0x47, 0x4d, 0x54, 0x0d, 0x0a, 0x43, 0x61,
        0x63, 0x68, 0x65, 0x2d, 0x43, 0x6f, 0x6e, 0x74, 0x72, 0x6f, 0x6c, 0x3a, 0x20, 0x70, 0x75, 0x62,
        0x6c, 0x69, 0x63, 0x2c, 0x20, 0x6d, 0x61, 0x78, 0x2d, 0x61, 0x67, 0x65, 0x3d, 0x32, 0x35, 0x39,
        0x32, 0x30, 0x30, 0x30, 0x0d, 0x0a, 0x53, 0x65, 0x72, 0x76, 0x65, 0x72, 0x3a, 0x20, 0x67, 0x77,
        0x73, 0x0d, 0x0a, 0x43, 0x6f, 0x6e, 0x74, 0x65, 0x6e, 0x74, 0x2d, 0x4c, 0x65, 0x6e, 0x67, 0x74,
        0x68, 0x3a, 0x20, 0x32, 0x31, 0x39, 0x0d, 0x0a, 0x58, 0x2d, 0x58, 0x53, 0x53, 0x2d, 0x50, 0x72,
        0x6f, 0x74, 0x65, 0x63, 0x74, 0x69, 0x6f, 0x6e, 0x3a, 0x20, 0x30, 0x0d, 0x0a, 0x58, 0x2d, 0x46,
        0x72, 0x61, 0x6d, 0x65, 0x2d, 0x4f, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x73, 0x3a, 0x20, 0x53, 0x41,
        0x4d, 0x45, 0x4f, 0x52, 0x49, 0x47, 0x49, 0x4e, 0x0d, 0x0a, 0x0d, 0x0a, 0x3c, 0x48, 0x54, 0x4d,
        0x4c, 0x3e, 0x3c, 0x48, 0x45, 0x41, 0x44, 0x3e, 0x3c, 0x6d, 0x65, 0x74, 0x61, 0x20, 0x68, 0x74,
        0x74, 0x70, 0x2d, 0x65, 0x71, 0x75, 0x69, 0x76, 0x3d, 0x22, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x6e,
        0x74, 0x2d, 0x74, 0x79, 0x70, 0x65, 0x22, 0x20, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x6e, 0x74, 0x3d,
        0x22, 0x74, 0x65, 0x78, 0x74, 0x2f, 0x68, 0x74, 0x6d, 0x6c, 0x3b, 0x63, 0x68, 0x61, 0x72, 0x73,
        0x65, 0x74, 0x3d, 0x75, 0x74, 0x66, 0x2d, 0x38, 0x22, 0x3e, 0x0a, 0x3c, 0x54, 0x49, 0x54, 0x4c,
        0x45, 0x3e, 0x33, 0x30, 0x31, 0x20, 0x4d, 0x6f, 0x76, 0x65, 0x64, 0x3c, 0x2f, 0x54, 0x49, 0x54,
        0x4c, 0x45, 0x3e, 0x3c, 0x2f, 0x48, 0x45, 0x41, 0x44, 0x3e, 0x3c, 0x42, 0x4f, 0x44, 0x59, 0x3e,
        0x0a, 0x3c, 0x48, 0x31, 0x3e, 0x33, 0x30, 0x31, 0x20, 0x4d, 0x6f, 0x76, 0x65, 0x64, 0x3c, 0x2f,
        0x48, 0x31, 0x3e, 0x0a, 0x54, 0x68, 0x65, 0x20, 0x64, 0x6f, 0x63, 0x75, 0x6d, 0x65, 0x6e, 0x74,
        0x20, 0x68, 0x61, 0x73, 0x20, 0x6d, 0x6f, 0x76, 0x65, 0x64, 0x0a, 0x3c, 0x41, 0x20, 0x48, 0x52,
        0x45, 0x46, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x67,
        0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x22, 0x3e, 0x68, 0x65, 0x72, 0x65,
        0x3c, 0x2f, 0x41, 0x3e, 0x2e, 0x0d, 0x0a, 0x3c, 0x2f, 0x42, 0x4f, 0x44, 0x59, 0x3e, 0x3c, 0x2f,
        0x48, 0x54, 0x4d, 0x4c, 0x3e, 0x0d, 0x0a,
    };

    const dual_data = [2][]const u8{
        &request,
        &response,
    };
    const lengths = [2]u16{ 139, 839 };

    defer if (gpa.deinit() == .leak) {
        std.posix.exit(1);
    };
    const allocator = gpa.allocator();

    for (dual_data, 0..) |value, index| {
        const frame = try ethernet_frame.EthernetFrame.readFromBytes(allocator, value, 14, lengths[index]);
        _ = frame;
    }
}
