import 'package:email_sender/classes.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'manager.dart';

const spacer = SizedBox(height: 10.0);
const biggerSpacer = SizedBox(height: 40.0);

TextStyle get headerStyle => const TextStyle(fontWeight: FontWeight.w600, fontSize: 16);

Widget recipientChip(String name, String email, Color color, VoidCallback setStateCallback) {
  return fluent.Tooltip(
      useMousePosition: false,
      style: const fluent.TooltipThemeData(
        maxWidth: 500,
        preferBelow: true,
        waitDuration: Duration.zero,
      ),
      richMessage: (name.isNotEmpty)
          ? TextSpan(
              children: [
                TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '\n'),
                TextSpan(text: email),
              ],
            )
          : TextSpan(text: email),
      child: Chip(
        side: BorderSide(color: color),
        color: WidgetStatePropertyAll(color.withOpacity(.25)),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8.0),
            Text(name.isNotEmpty ? name : email),
          ],
        ),
        onDeleted: () {
          Manager.extraRecipients.removeWhere((element) => element['email'] == email);
          setStateCallback();
        },
      ));
}

Widget ufficioChip(Ufficio ufficio, Color color, VoidCallback setStateCallback) {
  return fluent.Tooltip(
      useMousePosition: false,
      style: const fluent.TooltipThemeData(
        maxWidth: 500,
        preferBelow: true,
        waitDuration: Duration.zero,
      ),
      richMessage: TextSpan(
        children: [
          TextSpan(text: ufficio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: ' (${ufficio.entries.length} destinatari)\n', style: TextStyle(color: Colors.white.withOpacity(.5))),
          TextSpan(text: ufficio.entries.map((e) => "${e[1]} - ${e[2]}").join('\n')),
        ],
      ),
      child: Chip(
        side: BorderSide(color: color),
        color: WidgetStatePropertyAll(color.withOpacity(.25)),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups),
            const SizedBox(width: 8.0),
            Text(ufficio.nome),
          ],
        ),
        onDeleted: () {
          Manager.selectedGroups.removeWhere((element) => element.hash == ufficio.hash);
          setStateCallback();
        },
      ));
}

String get firma => '''
<br>
<div style="color:black; font-family: Verdana, sans-serif;">
  <p><b>-------------------</b></span></p>
  <p><b>Daniele Mason</b></span></p>
  <p>Agente di Zona</span></p>
  <p><b>Cell:</b></span> <span style="font-family: Calibri, sans-serif;">329 214 6700</span></p>
  <p><b><span style="font-family: Verdana, sans-serif;">Mail:</span></b> <span style="font-family: Calibri, sans-serif;"><a href="mailto:daniele.mason@maggioli.it" target="_blank">daniele.mason@maggioli.it</a></span></p>
</div>
<img src="https://ci3.googleusercontent.com/meips/ADKq_NavmJyAqNO0zX-PI-3YDgtgs4QyWAYa2z9hyGVkCau182rpdPgnNlmA1-spIED232xWUr0CyZlCVlQ_WRZku4N4tXx_DLRwfExY7jz1Zsm2oqpLjfiCCQs44xwfPzPPmDKXdJFCdB2ZRLcfxoeJ=s0-d-e1-ft#https://th.bing.com/th/id/OIP.635jUBCipADSKx7QEQwKLAAAAA?w=203&amp;h=166&amp;c=7&amp;r=0&amp;o=5&amp;pid=1.7" class="CToWUd" data-bit="iit"></span></p>
''';

String get privacy => '''
<br>
<br>
<span style="color:gray; font-size:11.0pt;">
    Ai sensi del <a href="https://presidenza.governo.it/USRI/confessioni/doc/dlgs196.pdf" target="_blank" rel="noopener noreferrer">D.Lgs. n. 196/2003</a>, si precisa che i dati contenuti in questa email sono destinati esclusivamente al destinatario indicato e possono contenere informazioni riservate e/o sensibili.
    <br>Qualora abbiate ricevuto questa email per errore, siete pregati di non utilizzarla e di contattare immediatamente il mittente per provvedere alla sua eliminazione.
</span>
''';

String zipSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#000000">
  <path d="M2 6.25V8H8.12868C8.32759 8 8.51836 7.92098 8.65901 7.78033L11.25 5.18934L9.71967 3.65901C9.29771 3.23705 8.72542 3 8.12868 3H5.25C3.45507 3 2 4.45507 2 6.25ZM2 17.75V9.5H8.12868C8.72542 9.5 9.29771 9.26295 9.71967 8.84099L13.0607 5.5H13.5V9.25C13.5 9.66421 13.8358 10 14.25 10H15V13H14.75C14.3358 13 14 13.3358 14 13.75C14 14.1642 14.3358 14.5 14.75 14.5H15V16H14.75C14.3358 16 14 16.3358 14 16.75C14 17.1642 14.3358 17.5 14.75 17.5H15V21H5.25C3.45507 21 2 19.5449 2 17.75ZM16.5 21H18.75C20.5449 21 22 19.5449 22 17.75V8.75C22 6.95507 20.5449 5.5 18.75 5.5H18V9.25C18 9.66421 17.6642 10 17.25 10H16.5V14.5H16.75C17.1642 14.5 17.5 14.8358 17.5 15.25C17.5 15.6642 17.1642 16 16.75 16H16.5V21ZM16.5 5.5H15V8.5H16.5V5.5Z" fill="#000000"/>
</svg>
''';
