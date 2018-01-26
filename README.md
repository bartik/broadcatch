# broadcatch
This script is used to check a torrent feed, download the torrent files and move them to a torrent client pickup directory.

## broadcatch.conf
See the example configuration file. The variable $TORRENTDIR is set to the pickup directory of the transmission client. The line starting with easy sets up the torrent extraction. The delimiter is the pipe character |. 

easy|https://eztv.ag/search/?q1=&q2=1934&search=Search|720p.HDTV.\*torrent|<a%20href=\\"|[\\"\&]

1. The first parameter P1 (**easy**) defines the way how the torrents will be extracted (see the file plugins/parse_{P1}.sh, the parse script is determined based on this first parameter P1 "easy"). See table below 

First parameter | Parser script
--------------- | -------------
anikraze|parse_anikraze.sh
easy|parse_easy.sh
eztv|parse_eztv.sh
ggkthx|parse_ggkthx.sh
kaizoku|parse_kaizoku.sh
mininova|parse_mininova.sh
rss|parse_rss.sh
2. The second parameter **https://eztv.ag/search/?q1=&q2=1934&search=Search** defines the URL where to find the list of the torrents which we want to download in html format.
```HTML
</td>
<td align="center" class="forum_thread_post">343.69 MB</td>
<td align="center" class="forum_thread_post">2d 19h</td>
<td align="center" class="forum_thread_post"><font color="green">1,428</font></td>
<td align="center" class="forum_thread_post_end"><a href="/forum/discuss/544732/" rel="nofollow" title="Discuss about Lethal Weapon S02E14 HDTV x264-SVA [eztv]:"><img src="/ezimg/s/1/3/chat_empty.png"
</tr>
<tr name="hover" class="forum_header_border">
<td width="35" class="forum_thread_post" align="center"><a href="/shows/1934/lethal-weapon/" title="Lethal Weapon Torrent"><img src="/images/eztv_show_info3.png" border="0" alt="Info" title="Lethal We
<td class="forum_thread_post">
<a href="/ep/544734/lethal-weapon-s02e14-720p-hdtv-x264-avs/" title="Lethal Weapon S02E14 720p HDTV x264-AVS [eztv] (1.30 GB)" alt="Lethal Weapon S02E14 720p HDTV x264-AVS [eztv] (1.30 GB)" class="epi
</td>
<td align="center" class="forum_thread_post">
<a href="magnet:?xt=urn:btih:dd36a4e759cebd0d30da939b57eafe54a20e4e41&dn=Lethal.Weapon.S02E14.720p.HDTV.x264-AVS%5Beztv%5D.mkv%5Beztv%5D&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A80&tr=udp%3A%2F%2Fglot
<a href="https://zoink.ch/torrent/Lethal.Weapon.S02E14.720p.HDTV.x264-AVS[eztv].mkv.torrent" rel="nofollow" class="download_1" title="Lethal Weapon S02E14 720p HDTV x264-AVS Torrent: Download Mirror #
</td>
<td align="center" class="forum_thread_post">1.30 GB</td>
 <td align="center" class="forum_thread_post">2d 19h</td>
<td align="center" class="forum_thread_post"><font color="green">248</font></td>
<td align="center" class="forum_thread_post_end"><a href="/forum/discuss/544734/" rel="nofollow" title="Discuss about Lethal Weapon S02E14 720p HDTV x264-AVS [eztv]:"><img src="/ezimg/s/1/3/chat_empty
</tr>
<tr name="hover" class="forum_header_border">
```
3. The fourth **<a%20href=\\"** and fifth **[\\"\&]** parameters defines the start and stop patterns between which a text can be found that contains torrent information. In our case it could be a magnet link
```
magnet:?xt=urn:btih:dd36a4e759cebd0d30da939b57eafe54a20e4e41
```
or a torrent file
```
https://zoink.ch/torrent/Lethal.Weapon.S02E14.720p.HDTV.x264-AVS[eztv].mkv.torrent
```
4. The third parameter **720p.HDTV.\*torrent** determines the pattern to search for in the above results. Only the matching lines are extracted. Thus we get this
```
https://zoink.ch/torrent/Lethal.Weapon.S02E14.720p.HDTV.x264-AVS[eztv].mkv.torrent
```
