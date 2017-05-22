---
layout: default
title: MicroJam
demovideo: SkUjjQd13KU
---
# MicroJam

![MicroJam in action]({{ site.baseurl }}/images/microjam.gif)

[![DOI](https://zenodo.org/badge/70703690.svg)](https://zenodo.org/badge/latestdoi/70703690)

MicroJam is a mobile app for sharing tiny touch-screen performances. Mobile applications that streamline creativity and social interaction have enabled a very broad audience to develop their own creative practices. While these apps have been very successful in visual arts (particularly photography), the idea of social music-making has not had such a broad impact. MicroJam includes several novel performance concepts intended to engage the casual music maker and inspired by current trends in social creativity support tools. Touch-screen performances are limited to 5-seconds, instrument settings are posed as sonic "filters", and past performances are arranged as a timeline with replies and layers. These features of MicroJam encourage users not only to perform music more frequently, but to engage with others in impromptu ensemble music making.


## Research Goals

- encourage everyday music-making with smartphones
- investigate asynchronous and distributed smartphone performance
- create generative microjams to mimic user styles

## Posts

<ul class="post-list">
  {% for post in site.posts %}
    <li>
      <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>
        <h2><a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a></h2>
    </li>
  {% endfor %}
</ul>

subscribe [via RSS]({{ "/feed.xml" | relative_url }})

## Demo Video

{% include_relative extras/youtubePlayer.html id=page.demovideo %}
