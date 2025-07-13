const std = @import("std");

const EXPECTED_INPUT_LENGHT = 32;
const BUFFER_BYTE_SIZE = 64;


pub fn main() !void {
    const args = std.os.argv;

    if (args.len < 2){
        try std.io.getStdErr().writer().print("Please pass a hexadecimal\n", .{});
        return;
    }

    var in = std.mem.span(args[1]);

    if (in.len != EXPECTED_INPUT_LENGHT){
        try std.io.getStdErr().writer().print("The hexadecimal need to be exactly {d} chars long\n", .{EXPECTED_INPUT_LENGHT});
        return;
    }

    var buffer : [BUFFER_BYTE_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const first_half = try stringToHexReversed(in[0..EXPECTED_INPUT_LENGHT/2], allocator);
    const second_half = try stringToHexReversed(in[EXPECTED_INPUT_LENGHT/2..in.len], allocator);

    const total_len = first_half.len + second_half.len;

    const bytes_array = try allocator.alloc(u8, total_len);

    @memcpy(bytes_array[0..first_half.len], first_half);
    @memcpy(bytes_array[first_half.len..total_len], second_half);

    const converted_bytes = try hexToString(bytes_array, allocator);

    const dash_positions = [_]usize{8, 13, 18, 23};

    var out: [36]u8 = undefined;

    var j: usize = 0;
    var i: usize = 0;
    var nextDash : usize = 0;

    while (j < out.len) {
        if (nextDash < dash_positions.len and j == dash_positions[nextDash]) {
            out[j] = '-';
            nextDash += 1;
        } else {
            out[j]   = converted_bytes[i];
            i += 1;
        }

        j += 1;

    }
    
    try std.io.getStdOut().writer().print("{s}\n", .{out});
}

fn stringToHexReversed (hex : []const u8, allocator : std.mem.Allocator) ![]u8 {
    const byte_len = hex.len / 2;
    const bytes = try allocator.alloc(u8, byte_len);

    var i : usize = 0;

    while(i < byte_len) : (i += 1){
        const pos = (byte_len - 1 - i) * 2;
        const hi = try std.fmt.charToDigit(hex[pos], 16);
        const lo = try std.fmt.charToDigit(hex[pos + 1], 16);
        bytes[i] = @as(u8, (hi << 4) | lo);
    }

    return bytes;
}

fn hexToString(hex: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const out_len = hex.len * 2;
    const out = try allocator.alloc(u8, out_len);    
    const hex_chars = "0123456789abcdef";

    var i: usize = 0;
    while (i < hex.len) : (i += 1) {
        out[i * 2]     = hex_chars[(hex[i] >> 4) & 0xF];
        out[i * 2 + 1] = hex_chars[hex[i] & 0xF];
    }

    return out;
}

