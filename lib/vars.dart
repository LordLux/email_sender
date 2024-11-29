import 'package:email_sender/src/classes.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:path/path.dart';

import 'functions.dart';
import '../src/manager.dart';

const spacer = SizedBox(height: 10.0);
const biggerSpacer = SizedBox(height: 40.0);

TextStyle get headerStyle => const TextStyle(fontWeight: FontWeight.w600, fontSize: 16);

TextSpan richTooltipRecipient(String name, String email, [bool remaining = false]) {
  return (name.isNotEmpty)
      ? TextSpan(
          children: [
            TextSpan(text: remaining ? "· $name" : name, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: remaining ? ' - ' : '\n'),
            TextSpan(text: email),
            if (remaining) const TextSpan(text: '\n'),
          ],
        )
      : TextSpan(text: remaining ? "\n$email" : email);
}

Widget? recipientChip(String name, String email, Color color, VoidCallback setStateCallback, [bool deleteable = true, bool copiable = true]) {
  if (email.isEmpty) return null;
  
  final String clipboardText = "${name.isNotEmpty ? name : email}${name.isNotEmpty ? " - $email" : ""}";
  color = color.lerpWith(Colors.white, .5);

  Widget chip = LayoutBuilder(builder: (context, constraints) {
    return Builder(builder: (context) {
      final Widget label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, color: Colors.white.withOpacity(.85)),
          const SizedBox(width: 8.0),
          Text(ellipsizeText(name.isNotEmpty ? name : email, constraints.maxWidth - 150), style: TextStyle(color: Colors.white.withOpacity(.85))),
        ],
      );
      if (deleteable)
        return Chip(
          side: BorderSide(color: color),
          color: WidgetStatePropertyAll(color.withOpacity(.25)),
          padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
          label: label,
          onDeleted: () {
            Manager.extraRecipients.removeWhere((element) => element['email'] == email);
            setStateCallback();
          },
        );
      return RawChip(
        side: BorderSide(color: color),
        color: WidgetStatePropertyAll(color.withOpacity(.25)),
        padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        label: label,
      );
    });
  });
  return fluent.Tooltip(
    useMousePosition: false,
    style: const fluent.TooltipThemeData(
      //maxWidth: 500,
      preferBelow: true,
      waitDuration: Duration.zero,
    ),
    richMessage: richTooltipRecipient(name, email),
    child: Builder(
      builder: (context) {
        if (copiable)
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => copiable ? copyToClipboard(clipboardText) : null,
            onSecondaryTap: () => copiable ? copyToClipboard(clipboardText) : null,
            child: chip,
          );
        return IgnorePointer(ignoring: true, child: chip);
      },
    ),
  );
}

TextSpan richTooltipUfficio(Ufficio ufficio, [bool remaining = false]) {
  return TextSpan(
    children: [
      TextSpan(text: remaining ? '· ${ufficio.nome}' : ufficio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: ' (${ufficio.entries.length} destinatari)\n    ', style: TextStyle(color: Colors.white.withOpacity(.5))),
      TextSpan(text: ufficio.entries.map((e) => "${e[1]} - ${e[2]}").join('\n    ')),
      if (remaining) const TextSpan(text: '\n'),
    ],
  );
}

Widget ufficioChip(Ufficio ufficio, Color color, VoidCallback setStateCallback, [bool deleteable = true, bool copiable = true]) {
  final String clipboardText = "${ufficio.nome}\n - ${ufficio.entries.map((e) => "${e[1]} - ${e[2]}").join('\n - ')}";

  Widget chip = LayoutBuilder(builder: (context, constraints) {
    return Builder(builder: (context) {
      final Widget label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups),
          const SizedBox(width: 8.0),
          Text(ellipsizeText(ufficio.nome, constraints.maxWidth - 110), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
      if (deleteable)
        return Chip(
          side: BorderSide(color: color),
          color: WidgetStatePropertyAll(color.withOpacity(.25)),
          padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
          label: label,
          onDeleted: () {
            Manager.selectedGroups.removeWhere((element) => element.hash == ufficio.hash);
            setStateCallback();
          },
        );
      return RawChip(
        side: BorderSide(color: color),
        color: WidgetStatePropertyAll(color.withOpacity(.25)),
        padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        label: label,
      );
    });
  });
  return fluent.Tooltip(
    useMousePosition: false,
    style: const fluent.TooltipThemeData(
      //maxWidth: 500,
      preferBelow: true,
      waitDuration: Duration.zero,
    ),
    richMessage: richTooltipUfficio(ufficio),
    child: Builder(
      builder: (context) {
        if (copiable)
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => copiable ? copyToClipboard(clipboardText) : null,
            onSecondaryTap: () => copiable ? copyToClipboard(clipboardText) : null,
            child: chip,
          );
        return IgnorePointer(ignoring: true, child: chip);
      },
    ),
  );
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
<img src="https://ci3.googleusercontent.com/meips/ADKq_NavmJyAqNO0zX-PI-3YDgtgs4QyWAYa2z9hyGVkCau182rpdPgnNlmA1-spIED232xWUr0CyZlCVlQ_WRZku4N4tXx_DLRwfExY7jz1Zsm2oqpLjfiCCQs44xwfPzPPmDKXdJFCdB2ZRLcfxoeJ=s0-d-e1-ft#https://th.bing.com/th/id/OIP.635jUBCipADSKx7QEQwKLAAAAA?w=203&amp;h=166&amp;c=7&amp;r=0&amp;o=5&amp;pid=1.7" class="CToWUd" data-bit="iit" alt="<Immagine Logo Maggioli>"></span></p>
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

String maggioliSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 200 210">
    <path style="fill:#fff;" d="M119.5 18.4v13.5h3.9v-4.1h2.3c2.9 0 5-1.5 5-4.8s-1.2-4.6-4.6-4.6h-6.5Zm7.4 4.7c0 1.4-1.1 1.4-2.1 1.4h-1.5v-2.7h1.7c1 0 1.8 0 1.8 1.3ZM135.1 25.1c0 4.1 2.6 7.1 6.4 7.1s6.4-2.9 6.4-7.1-2.6-7.1-6.4-7.1-6.4 2.9-6.4 7.1Zm8.9 0c0 3-1.5 3.7-2.5 3.7s-2.5-.7-2.5-3.7 1.5-3.7 2.5-3.7 2.5.7 2.5 3.7ZM103.4 18.4v13.5h3.9v-4.1h2.3c2.9 0 5-1.5 5-4.8s-1.2-4.6-4.6-4.6h-6.5Zm7.5 4.7c0 1.4-1.1 1.4-2.1 1.4h-1.5v-2.7h1.7c1 0 1.8 0 1.8 1.3ZM86.4 18.4v8.3c0 3.7 1.9 5.5 5.8 5.5s5.8-1.8 5.8-5.5v-8.3h-3.9v7.3c0 1.4 0 3.1-1.8 3.1s-1.9-1.7-1.9-3.1v-7.3h-3.9ZM77.8 31.9h3.9c-.3-.5-.4-1.7-.4-2.5V29c-.1-1.7-.8-2.9-1.9-3.4 1.3-.5 1.9-2 1.9-3.4 0-2.5-1.9-3.8-4.1-3.8h-7.4v13.5h3.9v-4.7h2.1c1.5 0 1.6 1.3 1.8 2.6 0 .7.1 1.4.3 2.1Zm-2.1-7.6h-2v-2.7h1.8c1.5 0 1.9.5 1.9 1.3 0 1.2-1 1.3-1.7 1.3ZM58.1 32.2c1.4 0 2.7-.5 3.6-1.7v1.4h2.6v-7.4h-5.2v2.9h1.7c-.2 1-1.1 1.5-2 1.5-2.4 0-2.9-2.2-2.9-3.5 0-1.1 0-3.9 2.6-3.9s1.7.7 1.8 1.7H64c-.6-3.2-2.6-5-5.8-5S52 20.3 52 25.4s2.3 6.9 6 6.9ZM135.1 153.8c-1.8 0-3.4 1.5-3.4 3.4s1.3 3.7 3.4 3.7 3.6-1.5 3.6-3.7-1.9-3.4-3.6-3.4ZM29.8 179.3h-.1l-9.9-34.5H5.7v1.6H11v43.7H5.7v1.6h12.7v-1.6h-5.3v-42.9h.2l13.1 44.5h1.8l13.6-44.5h.2v42.9h-5.4v1.6h17.5v-1.6h-5.3v-43.7h5.3v-1.6H40.2l-10.4 34.5zM183.2 157.3c0 2 1.3 3.7 3.4 3.7s3.6-1.5 3.6-3.7-1.9-3.4-3.6-3.4-3.4 1.5-3.4 3.4ZM153.9 163.2c-7.4 0-13.6 6.2-13.6 14.7s6.2 14.8 13.6 14.8 13.6-6.3 13.6-14.8-6.2-14.7-13.6-14.7Zm0 28c-7.1 0-7.2-7.4-7.2-13.3s0-13.3 7.2-13.3 7.2 7.4 7.2 13.3 0 13.3-7.2 13.3Z"/>
    <path style="fill:#fff;" d="M189.3 163.2c-2.5.6-5.3.7-7.9.7h-2.3v1.6h4.7v24.6h-8.3v-45.7c-2.5.5-5.3.6-7.9.6h-3v1.6h5.4V190h-5.4v1.6h28.8V190h-4.1v-26.9Z"/>
    <path style="fill:#fff;" d="M133.1 195.9c0-1.5-.3-3-1-4.3h10.5V190h-4.1v-26.9c-2.5.6-5.3.7-7.9.7h-8.5c-1.3-.4-2.7-.7-4.4-.7-7 0-10.1 5.3-10.1 9.7s2.1 6.4 5.3 7.9c-2.7.6-5.6 1.8-7.6 5.7-.4.7-.7 1.4-1 2.1-1.9-1.1-4.8-1.3-11.8-1.3H85c-1.1 0-1.8-.7-1.8-1.5 0-3 4.6-3.5 10.2-4.1 1.1-.1 2.1-.2 3.3-.4 1.5-.1 7.1-2.2 7.1-8.8s-.4-2.4-.7-3.3c-.2-.6-.3-1-.3-1.3 0-.7 1.5-1.7 2.2-1.7s.4.3.7.7c.4.6 1 1.4 1.7 1.4 1.5 0 2.3-1.3 2.3-2.7s-1.5-2.4-2.7-2.4c-2.3 0-4.5 2.3-5.2 3.9-1.8-2.7-4.7-4.1-8.8-4.1-7 0-10.1 5.3-10.1 9.7s2.1 6.4 5.3 7.9c-2.7.6-7 1.7-7 5.5v.5c-.3 1.2-1.1 3.2-2.5 3.2s-1.5-1.1-1.5-3.2v-16.7c0-2.8 0-6.9-9.6-6.9s-11.2 4.2-11.2 6.7 1.1 3.4 3 3.4 2.9-1.2 2.9-3-.9-2.2-1.6-2.7c-.3-.2-.5-.4-.5-.6 0-2 5-2.5 6.5-2.5 2.5 0 5.1 1 5.1 4.3v6.7c-10.7 0-17.4 3.7-17.6 10.2 0 5.2 3.8 6.9 8.2 6.9s7.1-1.3 9.5-4.3c.5 2.6 2 4.3 4.6 4.3s4.5-1.4 5.4-3.5c1.2 2.6 4.2 3 7 3.4h.1v.2c-3.5.9-8 2.7-8.2 7.4H0v10h200v-10h-67.6c.4-1.2.7-2.5.7-4.1ZM88 172.7c0-6.7 1.7-8.4 5.2-8.4 4.2 0 4.8 4.2 4.8 7.7s-.4 8-5.5 8-4.5-4.2-4.5-7.4Zm-16.5 10.8c0 2.8-.9 3.6-1.4 4.2H70c-1.7 1.6-3.2 2.1-5.4 2.1-3.2 0-5.4-2.1-5.4-5.6 0-6.5 7.8-7.2 12.4-7.3v6.5ZM93 205.8c-3.7 0-8.4-1.5-8.4-6s2.3-8 10.6-8 10.2 2 10.2 6.2-.5 7.8-12.4 7.8Zm19.8-33.1c0-6.7 1.7-8.4 5.2-8.4s4.8 4.2 4.8 7.7-.4 8-5.5 8-4.5-4.2-4.5-7.4Zm5.1 33.1c-3.7 0-8.4-1.5-8.4-6s2.3-8 10.6-8 10.2 2 10.2 6.2-.5 7.8-12.4 7.8Zm-.5-18.5h-7.5c-1.1 0-1.8-.7-1.8-1.5 0-3 4.6-3.5 10.2-4.1 1.1-.1 2.1-.2 3.3-.4 1.5-.1 7.1-2.2 7.1-8.8s-2-5.3-2-5.3c-.4-.7-1-1.3-1.6-1.8h8V190H131c-2.2-2.4-4.2-2.8-13.5-2.8Z"/>
    <path style="fill:#00379e;" d="M123.3 21.8v2.7h1.5c1 0 2.1 0 2.1-1.4s-.9-1.3-1.8-1.3h-1.7ZM107.3 21.8v2.7h1.5c1 0 2.1 0 2.1-1.4s-.9-1.3-1.8-1.3h-1.7ZM139 25.1c0 3 1.5 3.7 2.5 3.7s2.5-.7 2.5-3.7-1.5-3.7-2.5-3.7-2.5.7-2.5 3.7ZM75.5 21.6h-1.8v2.7h2c.7 0 1.7-.1 1.7-1.3s-.4-1.3-1.9-1.3ZM153.9 164.6c-7.1 0-7.2 7.4-7.2 13.3s0 13.3 7.2 13.3 7.2-7.4 7.2-13.3 0-13.3-7.2-13.3Z"/>
    <path style="fill:#00379e;" d="M0 0v200h80.5c.2-4.7 4.7-6.5 8.2-7.4v-.2h-.1c-2.8-.4-5.8-.8-7-3.4-.9 2.1-3 3.5-5.4 3.5s-4.1-1.7-4.6-4.3c-2.4 3-5.9 4.3-9.5 4.3s-8.2-1.7-8.2-6.9c.2-6.5 6.9-10.2 17.6-10.2v-6.7c0-3.3-2.6-4.3-5.1-4.3s-6.5.5-6.5 2.5.2.4.5.6c.6.4 1.6 1.1 1.6 2.7s-1.1 3-2.9 3-3-1.4-3-3.4 2.9-6.7 11.2-6.7 9.6 4.1 9.6 6.9v16.7c0 2.1 0 3.2 1.5 3.2s2.1-2 2.5-3.2v-.5c0-3.9 4.4-5 7-5.4-3.2-1.7-5.3-4.1-5.3-8.1s3.2-9.7 10.1-9.7 7 1.3 8.8 4.1c.7-1.6 2.9-3.9 5.2-3.9s2.7.6 2.7 2.4-.8 2.7-2.3 2.7-1.3-.8-1.7-1.4c-.3-.4-.5-.7-.7-.7-.7 0-2.2 1-2.2 1.7s.1.7.3 1.3c.3.9.7 2 .7 3.3 0 6.6-5.6 8.6-7.1 8.8-1.1.1-2.2.3-3.3.4-5.6.6-10.2 1.2-10.2 4.1s.8 1.5 1.8 1.5h7.5c7 0 9.9.2 11.8 1.3.3-.7.7-1.4 1-2.1 1.9-3.9 4.9-5.1 7.6-5.5-3.2-1.7-5.3-4.1-5.3-8.1s3.2-9.7 10.1-9.7 3.1.2 4.4.7h8.5c2.6 0 5.3 0 7.9-.7v26.9h4.1v1.6h-10.5c.7 1.3 1 2.7 1 4.3s-.2 2.9-.7 4.1h67.6V0H0Zm190.1 157.3c0 2.2-1.5 3.7-3.6 3.7s-3.4-1.7-3.4-3.7 1.6-3.4 3.4-3.4 3.6 1.5 3.6 3.4Zm-136-10.9h-5.3v43.7h5.3v1.6H36.5v-1.6h5.4v-42.8h-.1l-13.6 44.5h-1.8l-13.1-44.5h-.1v42.8h5.3v1.6H5.7v-1.6H11v-43.7H5.7v-1.6h14l9.9 34.6h.1L40 144.8h14v1.6Zm81 14.5c-2 0-3.4-1.7-3.4-3.7s1.6-3.4 3.4-3.4 3.6 1.5 3.6 3.4-1.5 3.7-3.6 3.7Zm18.8 31.7c-7.4 0-13.6-6.3-13.6-14.8s6.2-14.7 13.6-14.7 13.6 6.2 13.6 14.7-6.2 14.8-13.6 14.8Zm39.6-.9h-28.8v-1.6h5.4v-43.4h-5.4v-1.6h3c2.6 0 5.3-.1 7.9-.6v45.7h8.3v-24.6h-4.7V164h2.3c2.6 0 5.3 0 7.9-.7v26.9h4.1v1.6ZM147.9 25.1c0 4.1-2.6 7.1-6.4 7.1s-6.4-2.9-6.4-7.1 2.6-7.1 6.4-7.1 6.4 2.9 6.4 7.1ZM130.6 23c0 3.3-2.1 4.8-5 4.8h-2.3v4.1h-3.9V18.4h6.5c3.4 0 4.6 2.7 4.6 4.6Zm-16 0c0 3.3-2.1 4.8-5 4.8h-2.3v4.1h-3.9V18.4h6.5c3.4 0 4.6 2.7 4.6 4.6Zm-22.4 5.8c1.8 0 1.8-1.7 1.8-3.1v-7.3h3.9v8.3c0 3.7-1.9 5.5-5.8 5.5s-5.8-1.8-5.8-5.5v-8.3h3.9v7.3c0 1.4 0 3.1 1.9 3.1Zm-16.5-1.6h-2.1v4.7h-3.9V18.4h7.4c2.2 0 4.1 1.3 4.1 3.8s-.6 2.9-1.9 3.4c1.1.4 1.7 1.7 1.9 3.4v.4c0 .8.1 1.9.4 2.5h-3.9c-.2-.7-.3-1.4-.3-2.1-.1-1.3-.2-2.6-1.8-2.6Zm-17.4-9.1c3.2 0 5.3 1.9 5.8 5h-3.7c-.1-1-.9-1.7-1.8-1.7-2.6 0-2.6 2.8-2.6 3.8 0 1.3.5 3.6 2.9 3.6s1.8-.5 2-1.5h-1.7v-2.9h5.2v7.4h-2.5v-1.4c-1 1.2-2.3 1.7-3.7 1.7-3.7 0-6-3.1-6-6.9s3.4-7.2 6.2-7.2Z"/>
    <path style="fill:#00379e;" d="M120.1 191.8c-8.3 0-10.6 5.6-10.6 8 0 4.5 4.7 6 8.4 6 11.9 0 12.4-6.7 12.4-7.8 0-4.1-1.3-6.2-10.2-6.2ZM59.1 184.3c0 3.4 2.2 5.6 5.4 5.6s3.7-.6 5.4-2h.1v-.1c.6-.6 1.4-1.4 1.4-4.2v-6.5c-4.6 0-12.4.8-12.4 7.3ZM133 190.1v-24.6h-8c.6.5 1.1 1.1 1.6 1.8 0 0 2 2.2 2 5.3 0 6.6-5.6 8.6-7.1 8.8-1.1.1-2.2.3-3.3.4-5.6.6-10.2 1.2-10.2 4.1s.8 1.5 1.8 1.5h7.5c9.4 0 11.3.4 13.5 2.8h2.1Z"/>
    <path style="fill:#00379e;" d="M117.3 180.1c5.1 0 5.5-3.6 5.5-8s-.6-7.7-4.8-7.7-5.2 1.7-5.2 8.4.6 7.4 4.5 7.4ZM92.5 180.1c5.1 0 5.5-3.6 5.5-8s-.6-7.7-4.8-7.7c-3.5 0-5.2 1.7-5.2 8.4s.6 7.4 4.5 7.4ZM95.3 191.8c-8.3 0-10.6 5.6-10.6 8 0 4.5 4.7 6 8.4 6 11.9 0 12.4-6.7 12.4-7.8 0-4.1-1.3-6.2-10.2-6.2ZM93.2 164.4z"/>
</svg>
''';
