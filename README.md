# This project is discontinued ☠️

**Due to a change in personal circumstances with the founder of the project, we no longer have the time or motivation to work on Butterfly. If you are interested in a Flutter-based desktop then take a look at [dahliaOS](https://dahliaos.io/)**

# Ubuntu Butterfly 🦋 image builder 📀

This project is a work-in-progress 🚧 and far from complete, it builds OS images for Ubuntu Butterfly developers to tinker with. Approach with caution 🛑 **Certainly Ubuntu Butterfly is not a usable OS and the images available here are not representative of what Ubuntu Butterfly will become.** 🔮

## Usage

```bash
sudo ./image-build.sh
```

The `image-buiild.sh` script will install the required software on the host and then start and automated build. After a few minutes you should have a `ubuntu-butterfly.iso` ready for use which [`quickemu`](https://github.com/quickemu-project/quickemu) can run for you 😉

If you choose to use `quickemu` to run the iso, you will (presently) need to [manually create a VM configuration file](https://github.com/quickemu-project/quickemu#other-operating-systems) for Ubuntu Butterfly. 

## BEWARE! 💥

 - A copy of [`machinespawn`](https://github.com/wimpysworld/machinespawn) will be dropped in `/usr/local/bin` if a copy is not found in your `$PATH`.
   - `machinespawn` is also alpha software.
 - No hashes are generated, yet.
 - GNOME Flashback is the default desktop, just so the Ubiquity installer can function.
   - Weston and Wayfire are included and can be logged in to as a session or launched under GNOME Flashback.
   - **Wayfire needs configuring, it doesn't actually do anything right now.**

## Reference

This build script is inspired by the fantastic work of [Marcos Vallim](https://github.com/mvallim) and [Ken Gilmer](https://github.com/kgilmer) on [live-custom-ubuntu-from-scratch](https://github.com/mvallim/live-custom-ubuntu-from-scratch). In fact, large sections of code in this project have been lifted directly from live-custom-ubuntu-from-scratch and consequently we're using the same same [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0) license.
