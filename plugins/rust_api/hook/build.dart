import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.userDefines['build_assets'] == false) {
      stdout.writeln('Skipping the Rust build: user-define build_assets=false');
      return;
    }
    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoEnvironmentVariables: _bindgenEnvironment(input),
    ).run(input: input, output: output);
  });
}

// rquickjs runs bindgen on Android, which must load the NDK's libclang; Linux
// NDKs before r26 keep it under lib64, later ones and every macOS NDK under lib.
Map<String, String> _bindgenEnvironment(BuildInput input) {
  if (!input.config.buildCodeAssets ||
      input.config.code.targetOS != OS.android) {
    return const {};
  }
  final compiler = input.config.code.cCompiler?.compiler;
  if (compiler == null) {
    return const {};
  }
  final llvmRoot = File.fromUri(compiler).parent.parent;
  // The Windows NDK ships no libclang, so a Windows host points bindgen at a
  // separate LLVM install through the variable bindgen itself reads. A
  // libclang loaded that way cannot locate its own builtin headers, so it is
  // given the NDK clang's. native_toolchain_rust sets the per-target bindgen
  // arguments, which win over the generic ones, so its sysroot is restated.
  final override = Platform.environment['LIBCLANG_PATH'];
  if (override != null && override.isNotEmpty) {
    final directory = Directory(override);
    final triples = _androidTriples[input.config.code.targetArchitecture];
    final resourceDir = _clangResourceDir(llvmRoot);
    if (directory.existsSync() &&
        directory.listSync().any(_isLibclang) &&
        triples != null &&
        resourceDir != null) {
      final (:rust, :sysroot) = triples;
      final root = '${llvmRoot.path}/sysroot';
      final args =
          '--sysroot=$root -I$root/usr/include/$sysroot '
                  '-resource-dir=${resourceDir.path}'
              .replaceAll(r'\', '/');
      return {
        'LIBCLANG_PATH': override,
        'BINDGEN_EXTRA_CLANG_ARGS_${rust.replaceAll('-', '_')}': args,
      };
    }
  }
  for (final name in const ['lib', 'lib64']) {
    final directory = Directory(
      '${llvmRoot.path}${Platform.pathSeparator}$name',
    );
    if (directory.existsSync() && directory.listSync().any(_isLibclang)) {
      return {'LIBCLANG_PATH': directory.path};
    }
  }
  throw StateError(
    'No libclang under ${llvmRoot.path} (lib or lib64); the NDK Flutter '
    'passed cannot run bindgen for rquickjs',
  );
}

const _androidTriples = <Architecture, ({String rust, String sysroot})>{
  Architecture.arm64: (
    rust: 'aarch64-linux-android',
    sysroot: 'aarch64-linux-android',
  ),
  Architecture.arm: (
    rust: 'armv7-linux-androideabi',
    sysroot: 'arm-linux-androideabi',
  ),
  Architecture.x64: (
    rust: 'x86_64-linux-android',
    sysroot: 'x86_64-linux-android',
  ),
  Architecture.ia32: (
    rust: 'i686-linux-android',
    sysroot: 'i686-linux-android',
  ),
};

Directory? _clangResourceDir(Directory llvmRoot) {
  final clangLib = Directory(
    '${llvmRoot.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}clang',
  );
  if (!clangLib.existsSync()) {
    return null;
  }
  for (final entity in clangLib.listSync()) {
    final include = Directory('${entity.path}${Platform.pathSeparator}include');
    if (entity is Directory && include.existsSync()) {
      return entity;
    }
  }
  return null;
}

bool _isLibclang(FileSystemEntity entity) {
  return entity.path.split(Platform.pathSeparator).last.startsWith('libclang.');
}
