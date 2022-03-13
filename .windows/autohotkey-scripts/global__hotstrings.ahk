#SingleInstance Force

; ----
; How to use:
; Type "!shrug" (without quotes), then press <Space> to get ¯\_(ツ)_/¯
; ----

; ¯\_(ツ)_/¯
::!shrug::{U+00AF}{U+005C}_({U+30C4})_/{U+00AF}

; щ(ºДºщ)
::!why::{U+0449}({U+00BA}{U+0414}{U+00BA}{U+0449})

; (╯°□°)╯︵┻━┻
::!flip::({U+256f}{U+00B0}{U+25A1}{U+00B0}){U+256f}{U+FE35}{U+253B}{U+2501}{U+253B}

; ᕕ( ᐛ )ᕗ
::!lalala::{U+1555}( {U+141B} ){U+1557}

; (҂-_･) ︻デ═一▸
::!blam::({U+0482}-_{U+FF65}) {U+FE3B}{U+30C7}{U+2550}{U+4E00}{U+25B8}
; (҂-_･) ︻デ═一⠀⠀⠀· · ▸⠀⠀⠀⠀⠀⠀⠀⠀(XYZ)
; attacking something, with a few non-breakable spaces
; (to ensure they will stay as spaces in Teams for example)
::!blamfor::({U+0482}-_{U+FF65}) {U+FE3B}{U+30C7}{U+2550}{U+4E00}{U+2800}{U+2800}{U+2800}{U+00B7} {U+00B7} {U+25B8}{U+2800}{U+2800}{U+2800}{U+2800}{U+2800}{U+2800}{U+2800}{U+2800}(

; 👍
::!+1::{U+1F44D}

; 👀
::!eyes::{U+1F440}

; ™ (trademark)
::!tm::{U+2122}

::!lorem::Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

::!nohello::https://nohello.net/
::!nohi::https://nohello.net/

::!askwithtext::I don't have much time right now, but if you can ask your question in tchat I'll try to answer you or redirect you

; <details> block for github
; Multiline is documented at https://www.autohotkey.com/docs/Hotstrings.htm#continuation
::!ghdetails::
(
<details>
<summary>FILL_ME</summary>

DETAILS_HERE

</details>
)
