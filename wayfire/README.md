## Wayfire

This is the new desktop environment driving the default bookworm raspbian OS since Oct 2023.

Previously for X11 we'd use unclutter to remove the mouse, that doesn't work for wayland as
X11 / wayland are not compatible with eachother

So to support hiding the mouse - one of the [contributors for wayfire](https://github.com/soreau) [built a plugin](https://github.com/soreau/wayfire-hide-cursor)

https://github.com/soreau/wayfire-hide-cursor

This is part of wayfire-plugins-extra - but that isn't compiled or a package available
on raspbian package sources.

So we need to compile it ourselves

### Dependencies

```sh
sudo apt install libglibmm-2.4-dev libglm-dev libxml2-dev libpango1.0-dev libcairo2-dev wayfire-dev libwlroots-dev libwf-config-dev libvulkan-dev meson wayfire-dev
```

### Building

```sh
meson build
ninja -C build
```

If meson errors that it can't find the wayfire.pc, I found the quickest to resolve was to find it

```sh
find / -name wayfire.pc | grep -v permission
```

Which turned out to be in some obscure path and then copied it, once copied meson proceeded to work.
I guess we could have updated the pkgconfig path too once the path was identified

### Installing

Building for the most part is enough however the install will also generate an XML too
which is required

```sh
ninja -C build install
```

That should install the compiled plugin for 64bit to `/usr/lib/aarch64-linux-gnu/wayfire/`
and the XML to `/usr/share/wayfire/metadata`

Hopefully as time goes on the wayfire-plugin-extras will become part of the apt repo which won't
require us to compile from scratch.

This libhide-cursor.so was built from sources;

Source: https://github.com/soreau/wayfire-hide-cursor
GitSha: 5277cc9

#### Checksums:

Compiled file: libhide-cursor.so

sha1: 3c78b8967a22c53cbfcd1173b368e4169d27e3d5

sha256: 4f0c1e81ee6f12e72ec49a8e64fd2b9851c514b779df069649cbc74db267f604
