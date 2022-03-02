pub export const blob_type = "blob";

pub const Blob = extern struct {
    object: Object,
};

pub const lookupBlob = lookup_blob;
export fn lookup_blob(r: *Repository, oid: *const ObjectId) ?*Blob {
    if (lookupObject(r, oid)) |obj| {
        return obj.asType(.blob, false);
    } else {
        return @ptrCast(?*Blob, createObject(r, oid, allocBlobNode(r)));
    }
}

pub const parseBlobBuffer = parse_blob_buffer;
export fn parse_blob_buffer(item: *Blob, buffer: ?*anyopaque, size: c_ulong) c_int {
    _ = buffer;
    _ = size;
    item.object.parsed = true;
    return 0;
}

//

const std = @import("std");
const c = @cImport({
    @cInclude("cache.h");
    @cInclude("object.h");
    @cInclude("repository.h");
    @cInclude("alloc.h");
});

const allocBlobNode = c.alloc_blob_node;
const createObject = c.create_object;

const ObjectId = c.object_id;
const Repository = c.repository;

const lookupObject = lookup_object;
extern fn lookup_object(r: *Repository, oid: *const ObjectId) ?*Object;

const ObjectType = enum(c.enum_object_type) {
    bad = c.OBJ_BAD,
    none = c.OBJ_NONE,
    commit = c.OBJ_COMMIT,
    tree = c.OBJ_TREE,
    blob = c.OBJ_BLOB,
    tag = c.OBJ_TAG,
    ofs_delta = c.OBJ_OFS_DELTA,
    ref_delta = c.OBJ_REF_DELTA,
    any = c.OBJ_ANY,
    max = c.OBJ_MAX,
    _, // Non-exhaustive enum

    inline fn Type(comptime self: ObjectType) type {
        return comptime switch (self) {
            .blob => Blob,
            else => unreachable,
        };
    }
};

const Object = packed struct {
    parsed: bool,
    type: std.meta.Int(.unsigned, c.TYPE_BITS),
    flags: std.meta.Int(.unsigned, c.FLAG_BITS),
    id: ObjectId,

    pub inline fn asType(self: *Object, comptime object_type: ObjectType, quiet: bool) ?*object_type.Type() {
        return @ptrCast(?*object_type.Type(), object_as_type(self, object_type, quiet));
    }
    pub inline fn initTypeIfNone(self: *Object, object_type: ObjectType, quiet: bool) void {
        _ = object_as_type(self, object_type, quiet);
    }
    extern fn object_as_type(self: *Object, object_type: ObjectType, quiet: bool) ?*anyopaque;
};
