Optimized with [TDSI](http://code.google.com/p/apparat). Got nice performance while processing pitch shifting and time stretching.

## Current implemented： ##

Load and play accessable mp3 bit stream.

Wrapped AudioX class.Realtime sound speed controlling as buildin property(non-resampleing pitch shift), realtime pitch

shift as filter(no time stretching).

Several filters, including, Biquad,3bands EQ, stereo rot, stereo width range, cutoff, notch, phase, wave record, pitch

shift, etc.

Generators implemented: env, square, triangle, saw, sin, pink noise, white noise.

Analyzers implemented: FFT, BeatDetector.

Integrated Midas3 for parsing standard midi file. Will play midi file in the future.

_Currently on our site www.duobiduo.com, audio remix RIA's realtime changeing speed function is powered by the early version of this lib._

## Future features: ##

More filters.

Optimized core framework.

Over 32 channels sound together, which is limited by flashplayer.

Small and normal quality wave-table for midi playing.

More visualizations.

Soft sound effects sources.

经过[TDSI](http://code.google.com/p/apparat)的代码注入技术优化，在变调变速运算时能获得满意的性能。

## 目前已经实现的功能有： ##

flash播放可访问比特流mp3音频。

重新封装的AudioX类。音频实时播放变速不变调（no pitch shift）作为默认属性，滤镜方式音频实时播放变调不变速（no strenth）。

同时还实现了若干滤镜，包括Biquad，3档EQ，立体声反转，立体声域调节，cutoff，嵌波，相位调节，wave录制，变调保速，等等。

已经实现的音源发生器包括：包络发生器，方波，角波，锯齿波，正弦波，粉红噪音，白噪音。

已经实现的分析器包括：FFT，节拍检测。

同时还整合了Midas3，用于对标准midi文件解析，计划实现flash实时播放midi文件。

_目前多比多（www.duobiduo.com）网站的混音RIA的实时变速功能就应用了该库的早期版本。_

## 计划给这套代码增加更多的内容，包括： ##

更多的效果滤镜。

优化核心架构。

超过flash内置的32路音频限制。

小巧中等品质的软波表用于实时midi播放。

视觉效果。

软特效声源。