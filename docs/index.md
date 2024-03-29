---
layout: landing-page
---

<section id="howitworks" class="wrapper style1">
	<header class="major">
		<h2>How it works</h2>
		<p>Here's how to make music with MicroJam:</p>
	</header>
	<div class="container">
		<div class="row">
			<div class="4u">
				<section class="special box">
					<img src="{{ site.baseurl }}/images/microjam-iphone8-browse.png" class="image fit">
					<h3>Listen</h3>
					<p>You can browse other jams that have been uploaded or hit the "Jam!" tab to start a new one.</p>
				</section>
			</div>
			<div class="4u">
				<section class="special box">
					<img src="{{ site.baseurl }}/images/microjam-iphone8-perform.png" class="image fit">
					<h3>Perform</h3>
					<p>Tap, swirl, or swipe in the blue square to make your own tiny performance! Afterwards, hit "play" to hear what you've created. There's 9 instruments to try!</p>
				</section>
			</div>
			<div class="4u">
				<section class="special box">
					<img src="{{ site.baseurl }}/images/microjam-iphone8-robojam.png" class="image fit">
					<h3>RoboJam</h3>
					<p>Use our AI Music Bot to make "RoboJam" layers top of your performance! Or reply to performances to build complex sounds!</p>
				</section>
			</div>
		</div>
	</div>
</section>
			
<section id="video" class="wrapper style2">
	<header class="major">
		<h2>In action</h2>
	</header>
	<div class="container">
		{% include youtubePlayer.html id=site.demovideo %}
	</div>
</section>

<section id="about" class="wrapper style1">
	<div class="container">
		<div class="row">
			<div class="8u">
				<section>
					<h2>About MicroJam</h2>
					<a href="#" class="image fit"><img src="{{ site.baseurl }}/images/microjam-outdoor-music-making.jpg" alt="" /></a>
					<p>MicroJam is a mobile app for sharing tiny touch-screen performances. Mobile applications that streamline creativity and social interaction have enabled a very broad audience to develop their own creative practices. While these apps have been very successful in visual arts (particularly photography), the idea of social music-making has not had such a broad impact. MicroJam includes several novel performance concepts intended to engage the casual music maker and inspired by current trends in social creativity support tools. Touch-screen performances are limited to 5-seconds, instrument settings are posed as sonic "filters", and past performances are arranged as a timeline with replies and layers. These features of MicroJam encourage users not only to perform music more frequently, but to engage with others in impromptu ensemble music making.</p>
				</section>
			</div>
			<div class="4u">
				<section>
					<h3>Research Goals</h3>
					<ul>
						<li>encourage everyday music-making with smartphones</li>
						<li>investigate asynchronous and distributed smartphone performance</li>
						<li>create generative microjams to mimic user styles</li>
					</ul>
					<ul class="actions">
						<li><a href="#" class="button alt">Learn More</a></li>
					</ul>
				</section>
				<hr />
				<section>
					<h3>Development</h3>
					MicroJam is available on Github and archived at Zenodo. You can cite MicroJam via this DOI:
					<a href="https://zenodo.org/badge/latestdoi/70703690" class="image"><img src="{{ site.baseurl }}/images/zenodo.1313918.svg" alt="DOI" /></a>
				</section>
				<hr />
				<section>
					<h3>News</h3>
					<ul class="post-list">
					{% for post in site.posts %}
						<li><span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>
						<h4><a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a></h4></li>
					{% endfor %}
					</ul>
				</section>
			</div>
		</div>
	</div>
</section>