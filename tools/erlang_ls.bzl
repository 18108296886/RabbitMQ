load(
    "@rules_erlang//:erlang_app_info.bzl",
    "ErlangAppInfo",
)
load(
<<<<<<< HEAD
<<<<<<< HEAD
    "@rules_erlang//:util.bzl",
    "path_join",
)
load(
    "@rules_erlang//private:util.bzl",
    "additional_file_dest_relative_path",
=======
    "@rules_erlang//tools:erlang_toolchain.bzl",
    "erlang_dirs",
>>>>>>> 763cc758e2 (Add //tools:erlang_ls_files that generates a tree for Erlang LS)
)
load(
=======
>>>>>>> df45ece2aa (Turn the //tools:erlang_ls.config target into a generation script)
    "@rules_erlang//:util.bzl",
    "path_join",
)
load(
    "@rules_erlang//private:util.bzl",
    "additional_file_dest_relative_path",
)

def _erlang_ls_config(ctx):
<<<<<<< HEAD
<<<<<<< HEAD
    runtime_prefix = path_join(
        ctx.bin_dir.path,
=======
    runtime_prefix = path_join(
>>>>>>> df45ece2aa (Turn the //tools:erlang_ls.config target into a generation script)
        ctx.label.package,
        ctx.label.name + ".runfiles",
        ctx.workspace_name,
    )
<<<<<<< HEAD
=======
    out = ctx.actions.declare_file(ctx.label.name)

    (erlang_home, _, _) = erlang_dirs(ctx)
>>>>>>> 763cc758e2 (Add //tools:erlang_ls_files that generates a tree for Erlang LS)
=======
>>>>>>> df45ece2aa (Turn the //tools:erlang_ls.config target into a generation script)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = """#!/usr/bin/env bash

set -euo pipefail

<<<<<<< HEAD
BAZEL_OUT_ABSOLUTE_PATH="${{PWD%/{}}}/bazel-out"

cat << EOF
apps_dirs:
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/apps/*
deps_dirs:
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/deps/*
include_dirs:
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/apps
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/apps/*/include
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/deps
- ${{BAZEL_OUT_ABSOLUTE_PATH}}/*/bin/tools/erlang_ls_files/deps/*/include
=======
BAZEL_BIN_ABSOLUTE_PATH="${{PWD%/{}}}"

cat << EOF
apps_dirs:
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/apps/*
deps_dirs:
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/deps/*
include_dirs:
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/apps
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/apps/*/include
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/deps
- ${{BAZEL_BIN_ABSOLUTE_PATH}}/tools/erlang_ls_files/deps/*/include
>>>>>>> df45ece2aa (Turn the //tools:erlang_ls.config target into a generation script)
EOF
""".format(runtime_prefix),
    )

<<<<<<< HEAD
erlang_ls_config = rule(
    implementation = _erlang_ls_config,
    executable = True,
)

def _erlang_app_files(ctx, app, directory):
    app_info = app[ErlangAppInfo]
    app_path = path_join(directory, app_info.app_name)
    files = []
    for f in app_info.srcs + app_info.beam:
        relative_path = additional_file_dest_relative_path(app.label, f)
        dest = ctx.actions.declare_file(path_join(app_path, relative_path))
        ctx.actions.symlink(output = dest, target_file = f)
        files.append(dest)
    return files

def _erlang_ls_tree(ctx):
    apps = ctx.attr.apps
    deps = []

    for app in apps:
        app_info = app[ErlangAppInfo]
        for dep in app_info.deps:
            # this puts non rabbitmq plugins, like amqp10_client into deps,
            # but maybe those should be in apps? Does it matter?
            if dep not in deps and dep not in apps:
                deps.append(dep)

    files = []
    for app in apps:
        files.extend(
            _erlang_app_files(ctx, app, path_join(ctx.label.name, "apps")),
        )
    for dep in deps:
        files.extend(
            _erlang_app_files(ctx, dep, path_join(ctx.label.name, "deps")),
        )

    return [
        DefaultInfo(files = depset(files)),
    ]

<<<<<<< HEAD
erlang_ls_tree = rule(
    implementation = _erlang_ls_tree,
    attrs = {
        "apps": attr.label_list(
            providers = [ErlangAppInfo],
        ),
    },
=======
erlang_ls_config = rule(
    implementation = _erlang_ls_config,
    toolchains = [
        "@rules_erlang//tools:toolchain_type",
    ],
>>>>>>> 763cc758e2 (Add //tools:erlang_ls_files that generates a tree for Erlang LS)
=======
erlang_ls_config = rule(
    implementation = _erlang_ls_config,
    executable = True,
>>>>>>> df45ece2aa (Turn the //tools:erlang_ls.config target into a generation script)
)

def _erlang_app_files(ctx, app, directory):
    app_info = app[ErlangAppInfo]
    app_path = path_join(directory, app_info.app_name)
    files = []
    for f in app_info.srcs + app_info.beam:
        relative_path = additional_file_dest_relative_path(app.label, f)
        dest = ctx.actions.declare_file(path_join(app_path, relative_path))

        # ctx.actions.expand_template(
        #     template = f,
        #     output = dest,
        #     substitutions = {},
        # )
        ctx.actions.symlink(output = dest, target_file = f)
        files.append(dest)
    return files

def _erlang_ls_tree(ctx):
    apps = ctx.attr.apps
    deps = []

    for app in apps:
        app_info = app[ErlangAppInfo]
        for dep in app_info.deps:
            # this puts non rabbitmq plugins, like amqp10_client into deps,
            # but maybe those should be in apps? Does it matter?
            if dep not in deps and dep not in apps:
                deps.append(dep)

    files = []
    for app in apps:
        files.extend(
            _erlang_app_files(ctx, app, path_join(ctx.label.name, "apps")),
        )
    for dep in deps:
        files.extend(
            _erlang_app_files(ctx, dep, path_join(ctx.label.name, "deps")),
        )

    return [
        DefaultInfo(files = depset(files)),
    ]

erlang_ls_tree = rule(
    implementation = _erlang_ls_tree,
    attrs = {
        "apps": attr.label_list(
            providers = [ErlangAppInfo],
        ),
    },
)
