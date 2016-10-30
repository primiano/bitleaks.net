Title: How to fork Android on GitHub
Date: 2014-10-07
Tags: android
      git
Icon: icon.png
Abstract: Forking Android for personal embedded projects can be an interesting use case. Unfortunately, due to the complexity of Android's codebase, it might not be as straightforward as forking an average standalone project, even for of a single line change. This post explains how to maintain a fork of Android on GitHub in a sensible and efficient way.

![](index.png){.align-right}
I recently came across the need of forking an Android release (JellyBean + Freescale changes on top) to work with a [Udoo embedded board](http://www.udoo.org).  
Forking Android for personal embedded projects can be an interesting use case. Unfortunately, due to the complexity of Android's codebase, it might not be as straightforward as forking an average standalone project, even for a single line change.  
**This post explains**:  
- The fundamentals of Android source tree organization.  
- The principles of git-repo's XML manifests.  
- How to create a partial fork of an Android subproject on GitHub.  
- How to brew your own manifest pointing to your custom fork.  

This article assumes that you are familiar enough with Git and GitHub workflows.

Android source tree
-------------------
Android is a pretty big project counting dozens millions LOC. Other than the code size itself, what makes the situation more complex than usual is the hierarchical subproject structure.
The Android tree contains also several (~hundreds) projects which are often isolated and conceptually independent from each other (e.g., Kernel, C++ libraries, Java libraries, ...).
Its source tree, therefore, is not just a single huge Git project, rather a hierarchy of projects.  
A typical Android source tree looks like this:

    ~/android_root
      + build/        -> Git project of the build system
                         https://android.googlesource.com/platform/build.git

      + frameworks/   -> This is NOT a git repo itself
         + av/        -> Git project of media, A/V
                         https://android.googlesource.com/platform/av.git

         + base/      -> Git project of the main platform
                         https://android.googlesource.com/platform/base.git
      + external/
        + libfoo/     -> Git project of a third party library
                         https://android.googlesource.com/third_party/foo.git

        + libbar/     -> Another third party project
                         https://android.googlesource.com/somewhere/bar.git

If you are already familiar with [Git Submodules](http://git-scm.com/book/en/Git-Tools-Submodules), at this point you might have an idea of what I am talking about.
Android, however, does NOT use Git submodules (which are more recent than Android itself), rather a conceptually similar Google-brewed repository management software called [git-repo](https://code.google.com/p/git-repo/).  
All the Git projects for the Android AOSP are hosted on [android.googlesource.com](https://android.googlesource.com) (however, the fact that the all the projects have to be hosted there is not a mandatory requirement, as we will see later).


Anatomy of a manifest
----------------------
The aforementioned directory structure is defined in a XML (sigh) file called *manifest*. Conceptually a manifest is a table that associates a path on the filesystem (relative to the root of the checkout) to a given Git repository (and a particular branch / tag of that project).
Given a manifest file it is possible to check out, in a reproducible way, the full hierarchy of an Android tree at a given state (i.e. for a particular AOSP release).  

### What is a manifest?
Practically speaking, the manifest is a Git project itself, which contains a single file called default.xml.  
The manifests for the Android AOSP releases, for instance, are hosted [here](https://android.googlesource.com/platform/manifest/+refs).

When you follow the instructions for initialising an Android tree and run:  
`repo init -u https://android.googlesource.com/platform/manifest -b android-4.0.1_r1`  
what happens under the hoods is that git-repo checks out the manifest project in a hidden folder called .repo/manifests at the branch specified by the -b argument (android-4.0.1_r1 in our example).  
In the aforementioned case, the file that would be checked out in .repo/manifests/default.xml would be [this one](https://android.googlesource.com/platform/manifest/+/refs/heads/android-4.0.1_r1/default.xml).

Let's now take a look at how a simplified, but realistic, manifest for the toy checkout depicted above would look like:

    1. <?xml version="1.0" encoding="UTF-8"?>
    2. <manifest>
    3.    <remote fetch=".."
    4.            name="aosp"/>
    5.    <default revision="refs/tags/android-4.0.1_r1"
    6.             remote="aosp" />
    7.    <project path="build"           name="platform/build" />
    8.    <project path="frameworks/av"   name="platform/av" />
    9.    <project path="frameworks/base" name="platform/base" />
    10.   <project path="external/libfoo" name="third_party/foo" />
    11.   <project path="external/libbar" name="somewhere/bar" />
    12. </manifest>

Lines 3-6 are the most interesting one, let's discuss them in details.

*Line 3:* Defines the common root for the remote (as in [Git remote](http://git-scm.com/docs/git-remote)) to use. The fetch path can be either relative to the manifest project (..) or an url (e.g., https://android.googlesource.com/).  

*Line 4:* defines the name of the Git remote (by default it is "*origin*", but it is useful to decouple namespaces when dealing with different remotes as we will do in this tutorial).
Since all the projects in AOSP are fetched from the same base URL, AOSP manifests define only one remote, named "aosp".

*Line 5:* defines the default revision of each project defined in the manifest (see below). It can be either a Git SHA, a branch or a tag name.  

*Line 6:* defines which remote should be used, by default,  to fetch the specific project.

*Line 7:* defines that the contents of the folder ./build/ should be checked out from [aosp]/platform/build -> https://android.googlesource.com/platform/build

*Lines 8-11:* are pretty obvious at this point.


In very essence, this is a more compact notation for:

    <manifest>
       <remote fetch=".."
               name="aosp"/>
       <project path="build"  name="platform/build"
                remote="aosp" revision="refs/tags/android-4.0.1_r1" />
       <project path="frameworks/av"   name="platform/av"
                remote="aosp" revision="refs/tags/android-4.0.1_r1" />
       <project path="frameworks/base" name="platform/base"
                remote="aosp" revision="refs/tags/android-4.0.1_r1" />
       <project path="external/libfoo" name="third_party/foo"
                remote="aosp" revision="refs/tags/android-4.0.1_r1" />
       <project path="external/libbar" name="somewhere/bar"
                remote="aosp" revision="refs/tags/android-4.0.1_r1" />
    </manifest>

Forking a subproject
--------------------
Let's get now to the juicy part of the problem. Let's imagine that you want to create a fork of AOSP which is identical to android-4.0.1_r1, with the only exception that the default color for light background is green and not white.
What you want to do, is the following:

### Fork the project
https://android.googlesource.com/platform/frameworks/base.it (which is the one that contains the color definitions) at revision *android-4.0.1_r1*.  
There are two options for doing this:

1) Fork one of the existing GitHub projects from [https://github.com/android](https://github.com/android), which mirrors most of the projects and most of their branches from android.googlesource.com (e.g. [https://github.com/android/platform_frameworks_base](https://github.com/android/platform_frameworks_base))

2) If the project is not available on the github.com/android mirrors, just mirror it yourself:  

    $ cd ~/android_root/frameworks/base
    $ git checkout -b my_colors_branch -t aosp/android-4.0.1_r1
    $ hub create my_github_fork_of_base
    # (hub uses "origin" as default remote, which is confusing. Let's rename it to "github")
    $ git remote rename origin github


### Make your local changes
to the file [core/res/res/values/colors.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/colors.xml)

### Push your changes
to your fork of frameworks/base:

    $ git commit -a -m "Much color, such picture"
    $ git push github HEAD:shiny_colors

The last command will create a branch named *shiny_colors* in your newly created GitHub project, which is a fork of Android's tag *android-4.0.1_r1*.

Brewing your own manifest
-------------------------
At this point We have created one (or more) forks of Android sub-projects (only frameworks/base in this example), which is itself a nice thing. It means that we can now collaborate in civilized way with our friends / colleagues using a gitorius workflow and make our changes publicly available on GitHub.  
What we are still missing, at this point, is the ability for an external contributor to sync an Android tree which has our *shiny_color* changes in (without having to manually apply awkward patches). What we are still missing, at this point, is a custom manifest.  

The goal of our toy example is having a manifest which is identical to AOSP's android-4.0.1_r1 for all the projects, but with the exception of frameworks/base, which we just forked on GitHub.  
For that project, in fact, we want git-repo to pick our changes from https://github.com/user/my_github_fork_of_base.git instead of android.googlesource.com using the branch *shiny_colors*. The way we achieve this is the following:

### Create our fork of the manifest project
in the same way we forked frameworks/base.

    $ cd .repo/manifests/
    $ git checkout -b my_manifest -t aosp/android-4.0.1_r1
    $ hub create my_android_manifest
    $ git remote rename origin github

### Modify the manifest
adding our github remote and pointing frameworks/base to our fork:

    <?xml version="1.0" encoding="UTF-8"?>
    <manifest>
       <remote name="aosp" fetch="https://android.googlesource.com" />
       <remote name="github" fetch="https://github.com/primiano" />
       <default revision="refs/tags/android-4.0.1_r1" remote="aosp" />
       <project path="build"           name="platform/build" />
       <project path="frameworks/av"   name="platform/av" />
       <project path="frameworks/base" name="platform/base"
                remote="github" revision="shiny_colors" />
      <project path="external/libfoo" name="third_party/foo" />
      <project path="external/libbar" name="somewhere/bar" />
    </manifest>

### Commit our manifest
and push it to GitHub

    $ git commit -a -m "My manifest forked off android-4.0.1_r1 + shiny_colors"
    $ git push github HEAD:android_ICS_with_shiny_colors
This will create a branch named android_ICS_with_shiny_colors to your GitHub project https://github.com/user/my_android_manifest.  


### Sync the manifest
At this point you can finally distribute your manifest, telling your friends / contributors to check out the code as follows:  
`repo init -u https://github.com/user/my_android_manifest -b android_ICS_with_shiny_colors`  
This will check out a tree like the one in Chapter 1, with the only difference that frameworks/base will now point at your GitHub fork.

### A more complete example
Do you want to take a look to a more complete and less toy-ish example?  
Check out [this manifest hosted on my GitHub page](https://github.com/primiano/udoo_platform_manifest/blob/master/default.xml) I created to work on Android JB 4.3 the UDOO Quad board.

Happy Android hacking.
