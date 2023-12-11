## VGA bin 文件生成脚本

> Zhizhou Sha

最开始的 video 要求是 flv 格式。例如本目录下的 `dongfengpo.flv` 文件。

首先使用 `joyful.py` 将 flv 文件转换为 bin 文件。这一步主要是将图片存储为 rgb8 的二进制格式文件。

至此为止，视频的 bin 就准备好了

播放 video 的汇编代码是 `video_reader.s` 本目录下给的是我当时使用的版本。如果更改了 汇编代码 之后需要使用 Makefile 重新编译。编译方法是直接在目录下执行 `make` 即可。这一步会得到 `video_reader.bin` 文件。

在在线平台的时候，将 video bin 写入到一个 RAM 中，将 video_reader.bin 写入到另一个 RAM 中。这样 video 会在 VGA 里边循环播放了。

Note:
由于我没有实现 Flash 所以 RAM 的存储空间非常有限。所以要对视频的帧率和图片的大小进行控制

如果想播放更长或者更流畅的视频，可以考虑播放黑白视频，这样一个像素只需要一个 bit 而不是 rgb8 了

这个脚本当时跑的一个 demo video，左边是用 vga 跑的，右边是原始视频

https://github.com/JamesSand/ComputerOrganization2022InstructionPipeline/assets/98897204/81507551-5afa-449c-9fef-296823ddc2f0





