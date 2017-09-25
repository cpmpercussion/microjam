---
layout: post
title:  "Introducing RoboJam"
date:   2017-09-25 10:00:00 +0100
categories: prediction robojam ai
demovideo: n2xSHoB2_uY?t=1m2s
---

![The RoboJam workflow.]({{ site.baseurl }}/images/robojam-action-diagram.png){: class="fit image"}

This week I'm showing off MicroJam at the Cutting Edge conference as part of Oslo Innovation Week. One new feature of microjam that I'm very excited to demonstrate is "RoboJam", an AI musical helper built right into the app.

RoboJam allows you to instantly add a reply to your performance, created by an Artificial Neural Network. So now you can use MicroJam to collaborate with your friends, or with an AI system. 

![A Mixture Density Recurrent Neural Network as used in RoboJam]({{ site.baseurl}}/images/mdn-diagram.png){: class="fit image"}

RoboJam has been built using a Mixture Density Recurrent Neural Network, the network is trained to look at each event in a sequence of musical touchscreen interactions and to try to predict the next one. This means that it has to predict the location in x and y coordinates, as well as the time in the future that the next event will occur. We've used a mixture density network for this task, this means that the network's outputs are taken as the parameters for a mixture of probability models, perfect for this creative task where several choices of next step could be valid solutions.

The recurrent part of the network stores some information in between events in a kind of memory, allowing the network to model some of the temporal structure of performances. This memory also lets us use the network to "respond" to an existing performance. When you hit the RoboJam button, your performance is run through the network to condition the memory, and then a new 5-second performance is sampled from the network as the response.

You can see RoboJam in action in the following video. Each time you hit the RoboJam button a new performance is generated and it's interesting to see what kind of performances produce different responses. RoboJam is certainly an experimental feature and the subject of research, you could say that as a performer, it needs some practice! But we think that it shows a useful way for artificial intelligence and human creativity to work together.

{% include youtubePlayer.html id=page.demovideo %}
