#!/usr/bin/env python3
"""
UAsset Parser - Extract full structure from Unreal Engine .uasset files

Outputs JSON with: package info, names, imports, exports, properties, dependencies

Usage:
    python parse_uasset.py <path-to-uasset> [--format json|text] [--output file]
    python parse_uasset.py <path-to-uasset> --summary  # Quick summary only
"""

import struct
import sys
import json
import os
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any, BinaryIO

# UAsset Magic Numbers
PACKAGE_FILE_MAGIC = 0x9E2A83C1
PACKAGE_FILE_MAGIC_SWAPPED = 0xC1832A9E

# Package flags
PKG_UnversionedProperties = 0x00002000
PKG_FilterEditorOnly = 0x80000000


@dataclass
class FGuid:
    a: int = 0
    b: int = 0
    c: int = 0
    d: int = 0

    def __str__(self):
        return f"{self.a:08X}-{self.b:08X}-{self.c:08X}-{self.d:08X}"


@dataclass
class FGenerationInfo:
    export_count: int = 0
    name_count: int = 0


@dataclass
class FPackageFileSummary:
    tag: int = 0
    legacy_file_version: int = 0
    legacy_ue3_version: int = 0
    file_version_ue4: int = 0
    file_version_ue5: int = 0
    file_version_licensee_ue4: int = 0
    custom_version_count: int = 0
    total_header_size: int = 0
    folder_name: str = ""
    package_flags: int = 0
    name_count: int = 0
    name_offset: int = 0
    soft_object_paths_count: int = 0
    soft_object_paths_offset: int = 0
    localization_id: str = ""
    gatherable_text_data_count: int = 0
    gatherable_text_data_offset: int = 0
    export_count: int = 0
    export_offset: int = 0
    import_count: int = 0
    import_offset: int = 0
    depends_offset: int = 0
    string_asset_references_count: int = 0
    string_asset_references_offset: int = 0
    searchable_names_offset: int = 0
    thumbnail_table_offset: int = 0
    guid: str = ""
    generations: List[FGenerationInfo] = field(default_factory=list)
    saved_by_engine_version: str = ""
    compatible_with_engine_version: str = ""
    compression_flags: int = 0
    package_source: int = 0
    asset_registry_data_offset: int = 0
    bulk_data_start_offset: int = 0
    world_tile_info_data_offset: int = 0
    chunk_ids: List[int] = field(default_factory=list)
    preload_dependency_count: int = 0
    preload_dependency_offset: int = 0
    names_referenced_from_export_data_count: int = 0
    payload_toc_offset: int = 0
    data_resource_offset: int = 0


@dataclass
class FName:
    index: int = 0
    name: str = ""

    def __str__(self):
        return self.name


@dataclass
class FObjectImport:
    class_package: str = ""
    class_name: str = ""
    outer_index: int = 0
    object_name: str = ""
    package_name: str = ""
    is_optional: bool = False


@dataclass
class FObjectExport:
    class_index: int = 0
    super_index: int = 0
    template_index: int = 0
    outer_index: int = 0
    object_name: str = ""
    object_flags: int = 0
    serial_size: int = 0
    serial_offset: int = 0
    is_forced_export: bool = False
    is_not_for_client: bool = False
    is_not_for_server: bool = False
    package_guid: str = ""
    is_inherited_instance: bool = False
    package_flags: int = 0
    is_not_always_loaded_for_editor_game: bool = False
    is_asset: bool = False
    generate_public_hash: bool = False
    first_export_dependency: int = 0
    serialization_before_serialization_dependencies_size: int = 0
    create_before_serialization_dependencies_size: int = 0
    serialization_before_create_dependencies_size: int = 0
    create_before_create_dependencies_size: int = 0


class UAssetReader:
    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.file: Optional[BinaryIO] = None
        self.file_size: int = 0
        self.summary = FPackageFileSummary()
        self.names: List[FName] = []
        self.imports: List[FObjectImport] = []
        self.exports: List[FObjectExport] = []
        self.is_big_endian = False

    def _safe_read(self, size: int) -> bytes:
        """Read bytes with bounds checking"""
        pos = self.file.tell()
        if pos + size > self.file_size:
            raise ValueError(f"Attempted to read {size} bytes at offset {pos}, but file is only {self.file_size} bytes")
        data = self.file.read(size)
        if len(data) < size:
            raise ValueError(f"Only read {len(data)} of {size} bytes at offset {pos}")
        return data

    def read_int8(self) -> int:
        return struct.unpack('b', self._safe_read(1))[0]

    def read_uint8(self) -> int:
        return struct.unpack('B', self._safe_read(1))[0]

    def read_int16(self) -> int:
        fmt = '>h' if self.is_big_endian else '<h'
        return struct.unpack(fmt, self._safe_read(2))[0]

    def read_uint16(self) -> int:
        fmt = '>H' if self.is_big_endian else '<H'
        return struct.unpack(fmt, self._safe_read(2))[0]

    def read_int32(self) -> int:
        fmt = '>i' if self.is_big_endian else '<i'
        return struct.unpack(fmt, self._safe_read(4))[0]

    def read_uint32(self) -> int:
        fmt = '>I' if self.is_big_endian else '<I'
        return struct.unpack(fmt, self._safe_read(4))[0]

    def read_int64(self) -> int:
        fmt = '>q' if self.is_big_endian else '<q'
        return struct.unpack(fmt, self._safe_read(8))[0]

    def read_uint64(self) -> int:
        fmt = '>Q' if self.is_big_endian else '<Q'
        return struct.unpack(fmt, self._safe_read(8))[0]

    def read_guid(self) -> FGuid:
        return FGuid(
            self.read_uint32(),
            self.read_uint32(),
            self.read_uint32(),
            self.read_uint32()
        )

    def read_fstring(self) -> str:
        """Read an FString (length-prefixed, null-terminated)"""
        length = self.read_int32()
        if length == 0:
            return ""

        # Sanity check length
        if abs(length) > 1024 * 1024:  # 1MB max string length
            raise ValueError(f"Unreasonable string length: {length}")

        is_unicode = length < 0
        if is_unicode:
            length = -length
            if length > 0:
                data = self._safe_read(length * 2)
                try:
                    return data.decode('utf-16-le').rstrip('\x00')
                except:
                    return f"<decode_error:{length}>"
            return ""
        else:
            if length > 0:
                data = self._safe_read(length)
                try:
                    return data.decode('utf-8', errors='replace').rstrip('\x00')
                except:
                    return f"<decode_error:{length}>"
            return ""

    def read_fname(self) -> str:
        """Read an FName reference (index into name table)"""
        index = self.read_int32()
        number = self.read_int32()  # Instance number

        if 0 <= index < len(self.names):
            name = self.names[index].name
            if number > 0:
                return f"{name}_{number - 1}"
            return name
        return f"__INVALID_NAME_{index}__"

    def _scan_for_header_structure(self):
        """Scan for header structure in UE5.3+ format where custom versions changed"""
        # UE5.3+ has a different format - scan for known patterns

        # Reset to start of file and read more data for scanning
        self.file.seek(0)
        data = self.file.read(min(self.file_size, 50000))

        # First, try to find name table by looking for "None" FString pattern
        # FString format: int32 length + chars + null + 4-byte hash
        none_pattern = b'\x05\x00\x00\x00None\x00'  # length=5 + "None" + null
        none_pos = data.find(none_pattern)

        # For UE5.3+, find name table by scanning for FString patterns
        name_table_start = self._find_name_table_start(data)
        if name_table_start:
            self.summary.name_offset = name_table_start

            # Read names directly here since we won't call read_name_table
            offset = name_table_start
            while len(self.names) < 10000:
                result = self._try_read_fstring(data, offset)
                if not result:
                    break
                name, next_offset = result
                self.names.append(FName(index=len(self.names), name=name))
                offset = next_offset

            self.summary.name_count = len(self.names)

        # Extract embedded paths as imports (UE5.3+ stores them inline)
        self._extract_embedded_imports(data)
        return

    def _find_name_table_start(self, data: bytes) -> int:
        """Find the start of name table by scanning for valid FString sequences"""
        for start in range(200, min(len(data) - 100, 10000), 4):
            result = self._try_read_fstring(data, start)
            if result:
                name, next_off = result
                # Verify this is really a name table by checking next entries
                valid_count = 1
                off = next_off
                for _ in range(10):
                    result2 = self._try_read_fstring(data, off)
                    if result2:
                        valid_count += 1
                        off = result2[1]
                    else:
                        break
                if valid_count >= 5:
                    return start
        return 0

    def _try_read_fstring(self, data: bytes, offset: int):
        """Try to read an FString at offset, return (name, next_offset) or None"""
        if offset + 8 > len(data):
            return None
        length = struct.unpack_from('<i', data, offset)[0]
        if length <= 0 or length > 200:
            return None
        if offset + 4 + length + 4 > len(data):
            return None
        try:
            string_data = data[offset+4:offset+4+length]
            if b'\x00' not in string_data:
                return None
            name = string_data.decode('utf-8', errors='strict').rstrip('\x00')
            # Validate it looks like a valid name
            if not name or not all(c.isprintable() or c == '\x00' for c in name):
                return None
            return (name, offset + 4 + length + 4)
        except:
            return None

    def _extract_embedded_imports(self, data: bytes):
        """Extract embedded package paths as imports (UE5.3+ format)"""
        # Find /Script/ and /Game/ paths in header region
        patterns = [b'/Script/', b'/Game/', b'/Engine/']

        for pattern in patterns:
            pos = 0
            while pos < min(len(data), 50000):
                pos = data.find(pattern, pos)
                if pos == -1:
                    break

                # Find end of path
                end = pos
                while end < min(pos + 300, len(data)) and data[end] != 0:
                    end += 1

                if end > pos:
                    try:
                        path = data[pos:end].decode('utf-8', errors='replace')
                        # Create import entry for package references
                        if path.startswith('/Script/'):
                            package = path.split('.')[0]  # Get package part
                            imp = FObjectImport()
                            imp.class_package = '/Script/CoreUObject'
                            imp.class_name = 'Package'
                            imp.object_name = package.split('/')[-1]
                            imp.package_name = package
                            # Avoid duplicates
                            if not any(i.package_name == package for i in self.imports):
                                self.imports.append(imp)
                        elif path.startswith('/Game/') or path.startswith('/Engine/'):
                            package = path.split('.')[0]
                            imp = FObjectImport()
                            imp.class_package = '/Script/CoreUObject'
                            imp.class_name = 'Package'
                            imp.object_name = package.split('/')[-1]
                            imp.package_name = package
                            if not any(i.package_name == package for i in self.imports):
                                self.imports.append(imp)
                    except:
                        pass
                pos = end + 1

        self.summary.import_count = len(self.imports)

        # Fallback to offset scanning

        # Pattern: Look for header_size (medium value) followed by name patterns
        # header_size is usually between 500-500000 and aligned to 4
        # name_count is usually 10-10000
        # name_offset is usually > header_size position and < file_size

        best_match = None
        best_score = 0

        for offset in range(24, min(len(data) - 40, 500), 4):
            try:
                # Try to interpret as: header_size, folder_name_len, ...
                header_size = struct.unpack_from('<i', data, offset)[0]
                folder_len = struct.unpack_from('<i', data, offset + 4)[0]

                # Check if header_size is reasonable
                if not (100 < header_size < min(500000, self.file_size)):
                    continue

                # Check folder_len (0 or small positive, or negative for unicode)
                if not (-100 < folder_len < 500):
                    continue

                # If folder_len > 0, skip the string and check package_flags
                if folder_len > 0:
                    next_offset = offset + 8 + folder_len
                elif folder_len < 0:
                    next_offset = offset + 8 + (-folder_len * 2)
                else:
                    next_offset = offset + 8

                if next_offset + 20 > len(data):
                    continue

                # Package flags should be reasonable (often has bits set but not huge)
                pkg_flags = struct.unpack_from('<I', data, next_offset)[0]

                # name_count should be reasonable
                name_count = struct.unpack_from('<i', data, next_offset + 4)[0]
                name_offset = struct.unpack_from('<i', data, next_offset + 8)[0]

                if not (1 < name_count < 50000):
                    continue
                if not (100 < name_offset < self.file_size):
                    continue

                # Score this match
                score = 0
                if header_size % 4 == 0:
                    score += 1
                if name_offset % 4 == 0:
                    score += 1
                if name_offset > offset:
                    score += 2
                if 10 < name_count < 5000:
                    score += 2

                if score > best_score:
                    best_score = score
                    best_match = {
                        'offset': offset,
                        'header_size': header_size,
                        'folder_len': folder_len,
                        'pkg_flags': pkg_flags,
                        'name_count': name_count,
                        'name_offset': name_offset,
                        'next_offset': next_offset
                    }

            except struct.error:
                continue

        if best_match and best_score >= 3:
            # Use the scanned values
            self.summary.total_header_size = best_match['header_size']
            self.summary.package_flags = best_match['pkg_flags']
            self.summary.name_count = best_match['name_count']
            self.summary.name_offset = best_match['name_offset']

            # Try to find export/import counts
            search_offset = best_match['next_offset'] + 12
            for i in range(search_offset, min(search_offset + 100, len(data) - 20), 4):
                export_count = struct.unpack_from('<i', data, i)[0]
                export_offset = struct.unpack_from('<i', data, i + 4)[0]
                import_count = struct.unpack_from('<i', data, i + 8)[0]
                import_offset = struct.unpack_from('<i', data, i + 12)[0]

                if (0 < export_count < 10000 and
                    0 < import_count < 10000 and
                    100 < export_offset < self.file_size and
                    100 < import_offset < self.file_size):
                    self.summary.export_count = export_count
                    self.summary.export_offset = export_offset
                    self.summary.import_count = import_count
                    self.summary.import_offset = import_offset
                    break
        else:
            # Fallback - try to at least get file info
            self.summary.total_header_size = 0
            self.summary.name_count = 0
            self.summary.name_offset = 0

    def read_package_summary(self):
        """Read the package file summary header"""
        self.summary.tag = self.read_uint32()

        if self.summary.tag == PACKAGE_FILE_MAGIC_SWAPPED:
            self.is_big_endian = True
            self.summary.tag = PACKAGE_FILE_MAGIC

        if self.summary.tag != PACKAGE_FILE_MAGIC:
            raise ValueError(f"Invalid uasset magic: 0x{self.summary.tag:08X}")

        self.summary.legacy_file_version = self.read_int32()
        self.summary.legacy_ue3_version = self.read_int32()
        self.summary.file_version_ue4 = self.read_int32()

        if self.summary.legacy_file_version < -7:
            self.summary.file_version_ue5 = self.read_int32()

        self.summary.file_version_licensee_ue4 = self.read_int32()

        # UE5.3+ (file_version_ue5 >= 1000) has different header structure
        if self.summary.file_version_ue5 >= 1000:
            self._scan_for_header_structure()
            return

        # Custom versions - older UE5 format
        self.summary.custom_version_count = self.read_int32()

        # Check for invalid custom version count (negative or too large = UE5.3+ format)
        if self.summary.custom_version_count < 0 or self.summary.custom_version_count > 500:
            # UE5.3+ format or corrupted - try scanning approach
            self._scan_for_header_structure()
            return

        for _ in range(self.summary.custom_version_count):
            self.read_guid()  # Key
            self.read_int32()  # Version

        self.summary.total_header_size = self.read_int32()
        self.summary.folder_name = self.read_fstring()
        self.summary.package_flags = self.read_uint32()
        self.summary.name_count = self.read_int32()
        self.summary.name_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 516:
            self.summary.soft_object_paths_count = self.read_int32()
            self.summary.soft_object_paths_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 459:
            self.summary.localization_id = self.read_fstring()

        if self.summary.file_version_ue4 >= 516:
            self.summary.gatherable_text_data_count = self.read_int32()
            self.summary.gatherable_text_data_offset = self.read_int32()

        self.summary.export_count = self.read_int32()
        self.summary.export_offset = self.read_int32()
        self.summary.import_count = self.read_int32()
        self.summary.import_offset = self.read_int32()
        self.summary.depends_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 384:
            self.summary.string_asset_references_count = self.read_int32()
            self.summary.string_asset_references_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 510:
            self.summary.searchable_names_offset = self.read_int32()

        self.summary.thumbnail_table_offset = self.read_int32()

        guid = self.read_guid()
        self.summary.guid = str(guid)

        # Generations
        generation_count = self.read_int32()
        if generation_count > 100:
            raise ValueError(f"Unreasonable generation count: {generation_count}")
        for _ in range(generation_count):
            gen = FGenerationInfo()
            gen.export_count = self.read_int32()
            gen.name_count = self.read_int32()
            self.summary.generations.append(gen)

        # Engine version
        if self.summary.file_version_ue4 >= 336:
            major = self.read_uint16()
            minor = self.read_uint16()
            patch = self.read_uint16()
            changelist = self.read_uint32()
            branch = self.read_fstring()
            self.summary.saved_by_engine_version = f"{major}.{minor}.{patch}-{changelist} ({branch})"

        if self.summary.file_version_ue4 >= 444:
            major = self.read_uint16()
            minor = self.read_uint16()
            patch = self.read_uint16()
            changelist = self.read_uint32()
            branch = self.read_fstring()
            self.summary.compatible_with_engine_version = f"{major}.{minor}.{patch}-{changelist} ({branch})"

        self.summary.compression_flags = self.read_uint32()

        # Compressed chunks (should be 0 for modern assets)
        compressed_chunk_count = self.read_int32()
        if compressed_chunk_count > 1000:
            raise ValueError(f"Unreasonable compressed chunk count: {compressed_chunk_count}")
        for _ in range(compressed_chunk_count):
            self._safe_read(16)  # Skip chunk info

        self.summary.package_source = self.read_uint32()

        # Additional package names to cook (should be 0)
        additional_packages_count = self.read_int32()
        if additional_packages_count > 1000:
            raise ValueError(f"Unreasonable additional packages count: {additional_packages_count}")
        for _ in range(additional_packages_count):
            self.read_fstring()

        if self.summary.legacy_file_version > -7:
            self._safe_read(4)  # Texture allocations (deprecated)

        self.summary.asset_registry_data_offset = self.read_int32()
        self.summary.bulk_data_start_offset = self.read_int64()

        if self.summary.file_version_ue4 >= 224:
            self.summary.world_tile_info_data_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 326:
            chunk_id_count = self.read_int32()
            if chunk_id_count > 1000:
                raise ValueError(f"Unreasonable chunk ID count: {chunk_id_count}")
            for _ in range(chunk_id_count):
                self.summary.chunk_ids.append(self.read_int32())

        if self.summary.file_version_ue4 >= 507:
            self.summary.preload_dependency_count = self.read_int32()
            self.summary.preload_dependency_offset = self.read_int32()

        if self.summary.file_version_ue4 >= 516:
            self.summary.names_referenced_from_export_data_count = self.read_int32()

        if self.summary.file_version_ue4 >= 517:
            self.summary.payload_toc_offset = self.read_int64()

        if self.summary.file_version_ue5 >= 1000:
            self.summary.data_resource_offset = self.read_int32()

    def read_name_table(self):
        """Read the name table"""
        # Skip if names already populated (UE5.3+ scanning already did this)
        if self.names:
            return
        if self.summary.name_offset == 0 or self.summary.name_count == 0:
            return

        self.file.seek(self.summary.name_offset)

        for i in range(self.summary.name_count):
            name = self.read_fstring()

            # Hash (non-case preserving and case preserving)
            if self.summary.file_version_ue4 >= 64:
                self.read_uint16()  # NonCasePreservingHash
                self.read_uint16()  # CasePreservingHash

            self.names.append(FName(index=i, name=name))

    def read_import_table(self):
        """Read the import table"""
        # Skip if imports already populated (UE5.3+ scanning already did this)
        if self.imports:
            return
        if self.summary.import_offset == 0 or self.summary.import_count == 0:
            return

        self.file.seek(self.summary.import_offset)

        for _ in range(self.summary.import_count):
            imp = FObjectImport()
            imp.class_package = self.read_fname()
            imp.class_name = self.read_fname()
            imp.outer_index = self.read_int32()
            imp.object_name = self.read_fname()

            if self.summary.file_version_ue4 >= 520:
                imp.package_name = self.read_fname()

            if self.summary.file_version_ue5 >= 1000:
                imp.is_optional = self.read_int32() != 0

            self.imports.append(imp)

    def read_export_table(self):
        """Read the export table"""
        if self.summary.export_offset == 0 or self.summary.export_count == 0:
            return

        self.file.seek(self.summary.export_offset)

        for _ in range(self.summary.export_count):
            exp = FObjectExport()
            exp.class_index = self.read_int32()
            exp.super_index = self.read_int32()

            if self.summary.file_version_ue4 >= 508:
                exp.template_index = self.read_int32()

            exp.outer_index = self.read_int32()
            exp.object_name = self.read_fname()
            exp.object_flags = self.read_uint32()

            if self.summary.file_version_ue4 < 511:
                exp.serial_size = self.read_int32()
                exp.serial_offset = self.read_int32()
            else:
                exp.serial_size = self.read_int64()
                exp.serial_offset = self.read_int64()

            exp.is_forced_export = self.read_int32() != 0
            exp.is_not_for_client = self.read_int32() != 0
            exp.is_not_for_server = self.read_int32() != 0

            guid = self.read_guid()
            exp.package_guid = str(guid)

            if self.summary.file_version_ue5 >= 1000:
                exp.is_inherited_instance = self.read_int32() != 0

            exp.package_flags = self.read_uint32()

            if self.summary.file_version_ue4 >= 365:
                exp.is_not_always_loaded_for_editor_game = self.read_int32() != 0

            if self.summary.file_version_ue4 >= 485:
                exp.is_asset = self.read_int32() != 0

            if self.summary.file_version_ue5 >= 1004:
                exp.generate_public_hash = self.read_int32() != 0

            if self.summary.file_version_ue4 >= 507:
                exp.first_export_dependency = self.read_int32()
                exp.serialization_before_serialization_dependencies_size = self.read_int32()
                exp.create_before_serialization_dependencies_size = self.read_int32()
                exp.serialization_before_create_dependencies_size = self.read_int32()
                exp.create_before_create_dependencies_size = self.read_int32()

            self.exports.append(exp)

    def resolve_index(self, index: int) -> str:
        """Resolve an import/export index to a name"""
        if index == 0:
            return "None"
        elif index < 0:
            # Import
            import_idx = -index - 1
            if 0 <= import_idx < len(self.imports):
                imp = self.imports[import_idx]
                return f"Import:{imp.object_name} ({imp.class_name})"
            return f"Invalid Import {import_idx}"
        else:
            # Export
            export_idx = index - 1
            if 0 <= export_idx < len(self.exports):
                return f"Export:{self.exports[export_idx].object_name}"
            return f"Invalid Export {export_idx}"

    def parse(self) -> Dict[str, Any]:
        """Parse the uasset file and return structured data"""
        self.file_size = self.filepath.stat().st_size

        with open(self.filepath, 'rb') as f:
            self.file = f

            self.read_package_summary()
            self.read_name_table()
            self.read_import_table()
            self.read_export_table()

        # Build output structure
        result = {
            "file": str(self.filepath),
            "file_size": self.file_size,
            "summary": {
                "ue4_version": self.summary.file_version_ue4,
                "ue5_version": self.summary.file_version_ue5,
                "engine_version": self.summary.saved_by_engine_version,
                "package_guid": self.summary.guid,
                "package_flags": self.summary.package_flags,
                "name_count": len(self.names),
                "import_count": len(self.imports),
                "export_count": len(self.exports),
                "header_size": self.summary.total_header_size,
                "bulk_data_offset": self.summary.bulk_data_start_offset,
            },
            "names": [n.name for n in self.names],
            "imports": [
                {
                    "object_name": imp.object_name,
                    "class_name": imp.class_name,
                    "class_package": imp.class_package,
                    "outer": self.resolve_index(imp.outer_index) if imp.outer_index != 0 else None,
                    "package_name": imp.package_name or None,
                }
                for imp in self.imports
            ],
            "exports": [
                {
                    "object_name": exp.object_name,
                    "class": self.resolve_index(exp.class_index),
                    "super": self.resolve_index(exp.super_index) if exp.super_index != 0 else None,
                    "outer": self.resolve_index(exp.outer_index) if exp.outer_index != 0 else None,
                    "serial_size": exp.serial_size,
                    "serial_offset": exp.serial_offset,
                    "is_asset": exp.is_asset,
                    "flags": exp.object_flags,
                }
                for exp in self.exports
            ],
        }

        # Add dependency analysis
        dependencies = set()
        for imp in self.imports:
            if imp.class_package and imp.class_package != "/Script/CoreUObject":
                dependencies.add(imp.class_package)
            if imp.package_name:
                dependencies.add(imp.package_name)

        result["dependencies"] = sorted(dependencies)

        return result

    def get_summary(self) -> Dict[str, Any]:
        """Get a brief summary without full data"""
        data = self.parse()

        # Find main asset type
        main_asset = None
        for exp in data["exports"]:
            if exp["is_asset"]:
                main_asset = exp
                break

        if not main_asset and data["exports"]:
            main_asset = data["exports"][0]

        return {
            "file": data["file"],
            "file_size": data["file_size"],
            "engine_version": data["summary"]["engine_version"],
            "asset_type": main_asset["class"] if main_asset else "Unknown",
            "asset_name": main_asset["object_name"] if main_asset else "Unknown",
            "name_count": data["summary"]["name_count"],
            "import_count": data["summary"]["import_count"],
            "export_count": data["summary"]["export_count"],
            "dependency_count": len(data["dependencies"]),
        }


def format_text_output(data: Dict[str, Any]) -> str:
    """Format parsed data as readable text"""
    lines = []
    lines.append(f"=== UAsset: {data['file']} ===")
    lines.append(f"Size: {data['file_size']:,} bytes")
    lines.append("")

    s = data['summary']
    lines.append("--- Package Summary ---")
    lines.append(f"UE4 Version: {s['ue4_version']}")
    if s['ue5_version']:
        lines.append(f"UE5 Version: {s['ue5_version']}")
    lines.append(f"Engine: {s['engine_version']}")
    lines.append(f"GUID: {s['package_guid']}")
    lines.append(f"Names: {s['name_count']} | Imports: {s['import_count']} | Exports: {s['export_count']}")
    lines.append("")

    lines.append("--- Exports ---")
    for i, exp in enumerate(data['exports']):
        asset_marker = " [ASSET]" if exp['is_asset'] else ""
        lines.append(f"  [{i}] {exp['object_name']}{asset_marker}")
        lines.append(f"      Class: {exp['class']}")
        if exp['super']:
            lines.append(f"      Super: {exp['super']}")
        lines.append(f"      Size: {exp['serial_size']:,} bytes @ offset {exp['serial_offset']}")
    lines.append("")

    lines.append("--- Imports ---")
    for i, imp in enumerate(data['imports']):
        lines.append(f"  [{i}] {imp['object_name']} ({imp['class_name']})")
        lines.append(f"      Package: {imp['class_package']}")
    lines.append("")

    if data['dependencies']:
        lines.append("--- Dependencies ---")
        for dep in data['dependencies']:
            lines.append(f"  {dep}")
        lines.append("")

    lines.append("--- Name Table (first 50) ---")
    for i, name in enumerate(data['names'][:50]):
        lines.append(f"  [{i}] {name}")
    if len(data['names']) > 50:
        lines.append(f"  ... and {len(data['names']) - 50} more")

    return "\n".join(lines)


def resolve_game_path_to_file(game_path: str, content_root: str) -> str:
    """Convert /Game/Path/Asset to actual file path"""
    if game_path.startswith('/Game/'):
        relative = game_path[6:]  # Remove /Game/
        return os.path.join(content_root, relative + '.uasset')
    return None


def categorize_dependency(dep: str) -> str:
    """Categorize a dependency by its type"""
    if dep.startswith('/Script/'):
        return 'Module'
    elif '/GAS/' in dep or 'Ability' in dep or dep.startswith('/Game/') and 'GA_' in dep:
        return 'Ability'
    elif 'Montage' in dep or 'AMT_' in dep or '/Anim/' in dep:
        return 'Montage'
    elif 'BT_' in dep or '/BT/' in dep or 'BehaviorTree' in dep:
        return 'BehaviorTree'
    elif 'BTT_' in dep or 'BTD_' in dep or 'BTS_' in dep:
        return 'BTNode'
    elif 'BB_' in dep or 'Blackboard' in dep:
        return 'Blackboard'
    elif 'BP_' in dep and ('ene_' in dep.lower() or 'enemy' in dep.lower()):
        return 'Enemy'
    elif 'BP_' in dep:
        return 'Blueprint'
    elif 'Projectile' in dep:
        return 'Projectile'
    elif '/Engine/' in dep:
        return 'Engine'
    else:
        return 'Asset'


def analyze_names(names: list) -> Dict[str, Any]:
    """Analyze name table for insights"""
    analysis = {
        'gameplay_tags': [],
        'bt_nodes': [],
        'abilities': [],
        'montages': [],
        'properties': [],
        'enums': [],
        'warnings': []
    }

    for name in names:
        # Gameplay tags
        if name.startswith('Sipher.') or '.State.' in name or '.Ability.' in name:
            analysis['gameplay_tags'].append(name)
        # BT node types
        elif name.startswith('BT') and ('Composite' in name or 'Decorator' in name or 'Task' in name or 'Service' in name):
            analysis['bt_nodes'].append(name)
        # Abilities
        elif name.startswith('GA_') or name.endswith('_C') and 'Ability' in name:
            analysis['abilities'].append(name)
        # Montages
        elif name.startswith('AMT_') or 'Montage' in name:
            analysis['montages'].append(name)
        # Enums
        elif name.startswith('E') and '::' in name:
            analysis['enums'].append(name)
        # Warnings - TEMP or Test prefixes
        if 'TEMP_' in name or 'BP_Test' in name:
            analysis['warnings'].append(f"WIP asset: {name}")
        # Typo detection
        if 'Bawuchang' in name:  # Common typo
            analysis['warnings'].append(f"Possible typo 'Bawuchang' -> 'Baiwuchang': {name}")

    return analysis


def deep_analyze(filepath: str, content_root: str = None, max_depth: int = 2,
                 visited: set = None, depth: int = 0) -> Dict[str, Any]:
    """Recursively analyze asset and its dependencies"""
    if visited is None:
        visited = set()

    # Prevent infinite recursion
    abs_path = os.path.abspath(filepath)
    if abs_path in visited or depth > max_depth:
        return None
    visited.add(abs_path)

    # Auto-detect content root
    if content_root is None:
        # Try to find Content folder in path
        path_parts = filepath.replace('\\', '/').split('/')
        for i, part in enumerate(path_parts):
            if part == 'Content':
                content_root = '/'.join(path_parts[:i+1])
                break
        if content_root is None:
            content_root = os.path.dirname(filepath)

    try:
        reader = UAssetReader(filepath)
        data = reader.parse()
    except Exception as e:
        return {'error': str(e), 'file': filepath}

    # Categorize dependencies
    categorized_deps = {}
    for dep in data.get('dependencies', []):
        cat = categorize_dependency(dep)
        if cat not in categorized_deps:
            categorized_deps[cat] = []
        categorized_deps[cat].append(dep)

    # Analyze names
    name_analysis = analyze_names(data.get('names', []))

    result = {
        'file': filepath,
        'file_size': data['file_size'],
        'summary': data['summary'],
        'categorized_dependencies': categorized_deps,
        'name_analysis': name_analysis,
        'total_dependencies': len(data.get('dependencies', [])),
        'depth': depth
    }

    # Recursively analyze /Game/ dependencies
    if depth < max_depth:
        child_analyses = {}
        for dep in data.get('dependencies', []):
            if dep.startswith('/Game/'):
                dep_file = resolve_game_path_to_file(dep, content_root)
                if dep_file and os.path.exists(dep_file) and dep_file not in visited:
                    child_data = deep_analyze(dep_file, content_root, max_depth, visited, depth + 1)
                    if child_data and 'error' not in child_data:
                        child_analyses[dep] = child_data
        if child_analyses:
            result['analyzed_dependencies'] = child_analyses

    return result


def format_deep_analysis(data: Dict[str, Any], indent: int = 0) -> str:
    """Format deep analysis as readable text"""
    prefix = "  " * indent
    lines = []

    if indent == 0:
        lines.append("=" * 80)
        lines.append("DEEP ANALYSIS REPORT")
        lines.append("=" * 80)

    lines.append(f"{prefix}Asset: {data['file']}")
    lines.append(f"{prefix}Size: {data['file_size']:,} bytes")
    lines.append(f"{prefix}UE Version: {data['summary'].get('ue5_version', data['summary'].get('ue4_version', 'Unknown'))}")
    lines.append("")

    # Categorized dependencies
    cats = data.get('categorized_dependencies', {})
    if cats:
        lines.append(f"{prefix}--- Dependencies by Category ---")
        for cat, deps in sorted(cats.items()):
            lines.append(f"{prefix}  {cat} ({len(deps)}):")
            for dep in deps[:10]:  # Limit to 10 per category
                lines.append(f"{prefix}    - {dep}")
            if len(deps) > 10:
                lines.append(f"{prefix}    ... and {len(deps) - 10} more")
        lines.append("")

    # Name analysis
    analysis = data.get('name_analysis', {})

    if analysis.get('gameplay_tags'):
        lines.append(f"{prefix}--- Gameplay Tags ---")
        for tag in analysis['gameplay_tags']:
            lines.append(f"{prefix}  - {tag}")
        lines.append("")

    if analysis.get('bt_nodes'):
        lines.append(f"{prefix}--- BT Node Types ---")
        for node in sorted(set(analysis['bt_nodes'])):
            lines.append(f"{prefix}  - {node}")
        lines.append("")

    if analysis.get('warnings'):
        lines.append(f"{prefix}--- [!] WARNINGS ---")
        for warn in analysis['warnings']:
            lines.append(f"{prefix}  [!] {warn}")
        lines.append("")

    # Child analyses
    children = data.get('analyzed_dependencies', {})
    if children:
        lines.append(f"{prefix}--- Analyzed Dependencies ({len(children)}) ---")
        for dep_path, child_data in children.items():
            lines.append("")
            lines.append(f"{prefix}>> {dep_path}")
            lines.append(format_deep_analysis(child_data, indent + 1))

    return "\n".join(lines)


def main():
    import argparse

    # Set stdout to UTF-8 on Windows
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

    parser = argparse.ArgumentParser(description='Parse Unreal Engine .uasset files')
    parser.add_argument('path', help='Path to .uasset file')
    parser.add_argument('--format', choices=['json', 'text'], default='json',
                       help='Output format (default: json)')
    parser.add_argument('--output', '-o', help='Output file (default: stdout)')
    parser.add_argument('--summary', '-s', action='store_true',
                       help='Output brief summary only')
    parser.add_argument('--deep', '-d', action='store_true',
                       help='Deep analysis with recursive dependency reading')
    parser.add_argument('--max-depth', type=int, default=2,
                       help='Max recursion depth for deep analysis (default: 2)')
    parser.add_argument('--content-root', help='Content folder root path (auto-detected if not specified)')

    args = parser.parse_args()

    if not os.path.exists(args.path):
        print(f"Error: File not found: {args.path}", file=sys.stderr)
        sys.exit(1)

    try:
        if args.deep:
            data = deep_analyze(args.path, args.content_root, args.max_depth)
            if args.format == 'json':
                output = json.dumps(data, indent=2)
            else:
                output = format_deep_analysis(data)
        else:
            reader = UAssetReader(args.path)

            if args.summary:
                data = reader.get_summary()
            else:
                data = reader.parse()

            if args.format == 'json':
                output = json.dumps(data, indent=2)
            else:
                if args.summary:
                    output = "\n".join(f"{k}: {v}" for k, v in data.items())
                else:
                    output = format_text_output(data)

        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"Output written to {args.output}")
        else:
            print(output)

    except Exception as e:
        print(f"Error parsing {args.path}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
