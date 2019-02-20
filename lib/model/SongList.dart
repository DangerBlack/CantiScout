import "Song.dart";

class SongList{
  List<Song> list = new List<Song>();

  SongList(){
    /*Song c = new Song(
        id: 0,
        title: "Al fuoco di bivacco",
        author: "Ugo foscolo",
        time: "2018-01-05",
        body: "{cordpro}"
    );
    list.add(c);
    //c = songFromJson("{'id':'1','title':'Accogli Signore i nostri doni','author':'','body':'{title:Accogli Signore i nostri doni}\r\n\r\n[Do]Accogli Signore i nostri doni\r\nin [La-]questo misterioso in[Do]con[Do7]tro\r\n[Fa]tra la [Sol]nostra [Do]po[Mi-]ver[La-]t\u00e0 \r\n[Re-7]e la [Sol]tua gran[Do]dezza.\r\n\r\n[Do]Noi ti offriamo le cose \r\n[La-]che tu stesso ci hai [Do]da[Do7]to\r\n[Fa]e tu in [Sol]cambio [Do]do[Mi-]na[La-]ci \r\n[Re-7]dona[Sol]ci te [Do]stesso.\r\n\r\n{c:Ripetere le due strofe a canone}\r\n\r\nAccogli Signore i nostri doni.\r\n','time':'2014-08-18 18:54:54'},{'id':'2','title':'Acqua siamo noi','author':'','body':'{title:Acqua siamo noi}\r\n[Do]Acqua siamo noi dall'an[Sol]tica sor[Fa]gente ve[Do]niamo,\r\nfiumi siamo noi se i ru[Sol]scelli si [Fa]mettono in[Do]sieme,\r\nmari siamo noi se i tor[Sol]renti si [Fa]danno la [Do]mano,\r\nvita [Mi-]nuova [La-]c'\u00e8 se Ge[Fa]s\u00f9 \u00e8 in [Sol]mezzo a [Do]noi.\r\n\r\n{soc}\r\nE allora [Mi-]diamoci la [La-]mano\r\ne tutti in[Mi-]sieme cammi[La-]niamo\r\ned un o[Mi-]ceano di [La-]pace nasce[Sol4]r\u00e0.[Sol]\r\nE l'ego[Re-]ismo cancel[Sol]liamo\r\ne un cuore [Re-]limpido sen[Sol]tiamo\r\n\u00e8 Dio che [Re-]bagna del suo a[Sol]mor l'umani[Do]t\u00e0. [Fa][Sol]\r\n{eoc}\r\n\r\n[Do]Su nel cielo c'\u00e8 Dio [Sol]Padre che [Fa]vive per l'[Do]uomo\r\ncrea tutti noi e ci [Sol]ama di a[Fa]more infi[Do]nito,\r\nfigli siamo noi e fra[Sol]telli di [Fa]Cristo Si[Do]gnore,\r\nvita [Mi-]nuova [La-]c'\u00e8 quando [Fa]Lui \u00e8 in [Sol]mezzo a [Do]noi.\r\n\r\n{soc}E allora diamoci la mano...{eoc}\r\n\r\n[Do]Nuova umanit\u00e0 oggi [Sol]nasce da [Fa]chi crede in [Do]Lui,\r\nnuovi siamo noi se l'a[Sol]more \u00e8 la [Fa]legge di [Do]vita,\r\nfigli siamo noi se non [Sol]siamo di[Fa]visi da [Do]niente,\r\nvita e[Mi-]terna [La-]c'\u00e8 quando [Fa]Lui \u00e8 [Sol]dentro [Do]noi.\r\n\r\n{soc}E allora diamoci la mano...{eoc}\r\n','time':'2014-08-18 18:54:54'}");
    //c = songFromJson('{"id":"1","title":"Accogli Signore i nostri doni","author":"","body":"{title:Accogli Signore i nostri doni}\r\n\r\n[Do]Accogli Signore i nostri doni\r\nin [La-]questo misterioso in[Do]con[Do7]tro\r\n[Fa]tra la [Sol]nostra [Do]po[Mi-]ver[La-]t\u00e0 \r\n[Re-7]e la [Sol]tua gran[Do]dezza.\r\n\r\n[Do]Noi ti offriamo le cose \r\n[La-]che tu stesso ci hai [Do]da[Do7]to\r\n[Fa]e tu in [Sol]cambio [Do]do[Mi-]na[La-]ci \r\n[Re-7]dona[Sol]ci te [Do]stesso.\r\n\r\n{c:Ripetere le due strofe a canone}\r\n\r\nAccogli Signore i nostri doni.\r\n","time":"2014-08-18 18:54:54"}');
    c = songFromJson('{"id":"1","title":"Accogli Signore i nostri doni","author":"","body":"{title:Accogli Signore i nostri doni}\\r\\n\\r\\n[Do]Accogli Signore i nostri doni\\r\\nin [La-]questo misterioso in[Do]con[Do7]tro\\r\\n[Fa]tra la [Sol]nostra [Do]po[Mi-]ver[La-]t\\u00e0 \\r\\n[Re-7]e la [Sol]tua gran[Do]dezza.\\r\\n\\r\\n[Do]Noi ti offriamo le cose \\r\\n[La-]che tu stesso ci hai [Do]da[Do7]to\\r\\n[Fa]e tu in [Sol]cambio [Do]do[Mi-]na[La-]ci \\r\\n[Re-7]dona[Sol]ci te [Do]stesso.\\r\\n\\r\\n{c:Ripetere le due strofe a canone}\\r\\n\\r\\nAccogli Signore i nostri doni.\\r\\n","time":"2014-08-18 18:54:54"}');
    list.add(c);
    c = songFromJson('{"id":"2","title":"Acqua siamo noi","author":"","body":"{title:Acqua siamo noi}\\r\\n[Do]Acqua siamo noi dall\'an[Sol]tica sor[Fa]gente ve[Do]niamo,\\r\\nfiumi siamo noi se i ru[Sol]scelli si [Fa]mettono in[Do]sieme,\\r\\nmari siamo noi se i tor[Sol]renti si [Fa]danno la [Do]mano,\\r\\nvita [Mi-]nuova [La-]c\'\\u00e8 se Ge[Fa]s\\u00f9 \\u00e8 in [Sol]mezzo a [Do]noi.\\r\\n\\r\\n{soc}\\r\\nE allora [Mi-]diamoci la [La-]mano\\r\\ne tutti in[Mi-]sieme cammi[La-]niamo\\r\\ned un o[Mi-]ceano di [La-]pace nasce[Sol4]r\\u00e0.[Sol]\\r\\nE l\'ego[Re-]ismo cancel[Sol]liamo\\r\\ne un cuore [Re-]limpido sen[Sol]tiamo\\r\\n\\u00e8 Dio che [Re-]bagna del suo a[Sol]mor l\'umani[Do]t\\u00e0. [Fa][Sol]\\r\\n{eoc}\\r\\n\\r\\n[Do]Su nel cielo c\'\\u00e8 Dio [Sol]Padre che [Fa]vive per l\'[Do]uomo\\r\\ncrea tutti noi e ci [Sol]ama di a[Fa]more infi[Do]nito,\\r\\nfigli siamo noi e fra[Sol]telli di [Fa]Cristo Si[Do]gnore,\\r\\nvita [Mi-]nuova [La-]c\'\\u00e8 quando [Fa]Lui \\u00e8 in [Sol]mezzo a [Do]noi.\\r\\n\\r\\n{soc}E allora diamoci la mano...{eoc}\\r\\n\\r\\n[Do]Nuova umanit\\u00e0 oggi [Sol]nasce da [Fa]chi crede in [Do]Lui,\\r\\nnuovi siamo noi se l\'a[Sol]more \\u00e8 la [Fa]legge di [Do]vita,\\r\\nfigli siamo noi se non [Sol]siamo di[Fa]visi da [Do]niente,\\r\\nvita e[Mi-]terna [La-]c\'\\u00e8 quando [Fa]Lui \\u00e8 [Sol]dentro [Do]noi.\\r\\n\\r\\n{soc}E allora diamoci la mano...{eoc}\\r\\n","time":"2014-08-18 18:54:54"}');
    list.add(c);
    c = new Song(
        id: 0,
        title: "La fede",
        author: "Ugo foscolo",
        time: "2018-01-05",
        body: "{cordpro}"
    );
    list.add(c);*/
  }

  Song get(int i){
    return list[i];
  }
}