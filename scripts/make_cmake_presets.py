#!/usr/bin/env python

"""Build cmake presets from existing presets."""

import json
import itertools
import re
from pathlib import Path


def get_vendor_dict(preset):
    d = preset.get("vendor", None)
    if d is None:
        return None
    d = d.get("tula_cmake", None)
    if d is None:
        return None
    return d


def collect_groups(presets):

    groups = dict()
    for preset in presets:
        d = get_vendor_dict(preset)
        group = d.get("preset_group", None)
        if group is None:
            continue
        if group in groups:
            groups[group].append(preset)
        else:
            groups[group] = [preset]
    return groups


def make_presets(generator, groups):

    def get_preset_names(key):
        return [(key, p['name']) for p in groups[key]]

    def expand_inherits(item):
        m = re.match(r'{(.+)}', item)
        if m is not None:
            group_name = m[1]
            print(group_name)
            return get_preset_names(group_name)
        return [(None, item)]

    items = [
        expand_inherits(i) for i in generator['inherits']]

    items = itertools.product(*items)
    ps = list()
    for item in items:
        item = dict(item)
        p = dict()
        p['name'] = generator['name'].format(**item)
        p['description'] = generator['description'].format(**item).capitalize()
        p['inherits'] = list(item.values())
        print(f"generated preset: {p['name']}")
        ps.append(p)
    return ps


if __name__ == "__main__":
    import sys
    input_file = sys.argv[1]

    with open(input_file, 'r') as fo:
        presets = json.load(fo)

    # collect the preset groups

    groups = collect_groups(
        presets.get('configurePresets', list()) +
        presets.get('buildPresets', list()) +
        presets.get('testPresets', list()))

    # generate

    d = get_vendor_dict(presets)
    generators = d.get("generators", list())
    for generator in generators:
        ps = make_presets(generator, groups)
        # update to presets
        presets[generator['type']].extend(ps)

    output_file = Path('CMakePresets.json')
    if output_file.exists():
        if len(sys.argv) > 2 and sys.argv[2] != '-f':
            raise ValueError("output file exists.")
        else:
            print(f"overwrite {output_file}")
    with open(output_file, 'w') as fo:
        json.dump(presets, fo, indent=2)
