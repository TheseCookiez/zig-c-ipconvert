const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const print = std.debug.print;
const heap_allocator = std.heap.page_allocator;
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("ipv4_converter.h");
});

pub fn num_to_str(comptime T: type, number: T, buf: *[100]u8) ![]u8 {
    const result = try std.fmt.bufPrint(buf, "{?}", .{number});
    return result;
}

pub fn readfile(allocator: *const Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile("ipfile.csv", .{});
    defer file.close();
    const f_size = (try file.stat()).size;
    const f_data = try file.readToEndAlloc(allocator.*, f_size);

    return f_data;
}

pub fn writeFile(f_data: []u8, f_name: []u8) !void {
    const file = try std.fs.cwd().createFile(f_name, .{});
    defer file.close();
    try file.writer().writeAll(f_data);
}

pub fn main() !void {
    const f_data = try readfile(&heap_allocator);
    const file = try std.fs.cwd().createFile("result.txt", .{});
    defer file.close();

    var ip_arr_list = std.ArrayList(u32).init(heap_allocator);

    var buf: [100]u8 = undefined;

    var split = std.mem.splitScalar(u8, f_data, '\n');
    while (split.next()) |value| {
        const value_as_int = c.convertIPv4ToInt(@ptrCast(value.ptr));

        try ip_arr_list.append(value_as_int);
        const ip_int_as_u8 = try num_to_str(u32, value_as_int, &buf);
        try file.writer().writeAll(ip_int_as_u8);
        try file.writer().writeAll("\n");
    }
    print("Finished parsing IPv4 to int\n", .{});
    const ip_arr_list_slice = try ip_arr_list.toOwnedSlice();
    std.mem.sort(u32, ip_arr_list_slice, {}, std.sort.asc(u32));
    const sorted_file = try std.fs.cwd().createFile("sorted_result.txt", .{});
    defer sorted_file.close();

    const ip_arr_list_slice_as_u8 = try std.fmt.allocPrint(heap_allocator, "{d}", .{ip_arr_list_slice});
    var split_output = std.mem.splitScalar(u8, ip_arr_list_slice_as_u8, ',');
    while (split_output.next()) |value| {
        try sorted_file.writer().writeAll(value);
        try sorted_file.writer().writeAll("\n");
    }
}
