# Ubuntu Butterfly 🦋 image builder 📀

This project is a work-in-progress 🚧 and far from complete, it builds OS images for Ubuntu Butterfly developers to tinker with. Approach with caution 🛑 **Certainly Ubuntu Butterfly is not a usable OS and the images available here are not representative of what Ubuntu Butterfly will become.** 🔮

## Usage

```bash
sudo ./image-build.sh
```

The `image-buiild.sh` script will install the required software on the host and then start and automated build. After a few minutes you should have a `ubuntu-butterfly.iso` ready for use which [`quickemu`](https://github.com/quickemu-project/quickemu) can run for you 😉

## BEWARE! 💥

 - A copy of [`machinespawn`](https://github.com/wimpysworld/machinespawn) will be dropped in `/usr/local/bin` if a copy is not found in your `$PATH`.
   - `machinespawn` is also alpha software.
 - No hashes are generated, yet.

## Reference

This build script is inspired by the fantastic work of [Marcos Vallim](https://github.com/mvallim) and [Ken Gilmer](https://github.com/kgilmer) on [live-custom-ubuntu-from-scratch](https://github.com/mvallim/live-custom-ubuntu-from-scratch). In fact, large sections of code in this project have been lifted directly from live-custom-ubuntu-from-scratch and consequently we're using the same same [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0) license.
