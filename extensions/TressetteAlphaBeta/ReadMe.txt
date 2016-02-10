== TressetteAlphaBeta
Con questo progetto ho cercato di creare un estensione di ruby da applicare alla distribuzione
allegata al software della Cuperativa. 
Con la Cuperativa 1.2.9, la versione di Ruby allegata è la 1.8.6, le ragioni per cui ho usato 
una versione così datata è che FxRuby funziona bene con al massimo ruby 1.8.7 e l'editor Arachno
con 1.8.6.
Per compilare un estensione di ruby sotto windows viene usato il devkit (http://rubyinstaller.org/add-ons/devkit/).
anche perché ogni versione di ruby sotto windows dell'installer è compilata usando devkit.
L'eccezione è ruby 1.8.6 della cuperativa, che è stato compilato con MSVS6.
Lontano dall'idea di riesumare MSVS6, ho messo su la prima versione realizzata col devkit,
vale a dire la ruby 1.8.7 (2010-08-16 patchlevel 302) [i386-mingw32].
Per fare questo ho scompattato lo zip ruby-1.8.7-p302-i386-mingw32.7z in una dircetory.
Poi ho fatto lo stesso con il DevKit DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe, che è il devikit
fino alla versione 1.9.3.
Siccome ho molte versioni di ruby installate, non ho messo ruby nel path. Però apro una finestra di
comando e metto qualcosa di simile a:
set PATH=D:\Biblio\ruby\ruby_win32_deployed\common\ruby_0_0_3\ruby\bin;%PATH%
Nella stessa finestra con ruby settato, si va nella directory del devkit.
Qui si lancia devkitvars.bat per avere tutti i tools per compilare di mingw. Poi si setta l'ambiente con:
ruby dk.rb init
Si edita il file config.yml e si mette dentro qualcosa di simile a:
 - D:/Biblio/ruby/ruby_win32_deployed/common/ruby_0_0_3/ruby
 Ora lo si installa con 
 ruby dk.rb install
 A questo punto è possibile compilare gem nativi.
 (https://github.com/oneclick/rubyinstaller/wiki/Development-Kit)

 == L'estensione ruby
 Ho messo in progetto di visual studio 2015 tutto il codice cpp che mi serve per l'algoritmo alpha-beta
 del tressette a 4 giocatori. Il codice viene dal mio progetto tressette che ho anche compilato anche sotto linux.
 In VS2015 non voglio dipendenze da Ruby, nenache da SDL, quindi ho creato un progetto che crea una dll senza il file che interfaccia
 ruby, in questo caso il file RubyTre4AlphaBeta.
 Quando il codice ha compilato in VS2015, sono partito per craere l'estensione.
 Per prima cosa nella stessa directory del codice cpp, ho creato il file extconf.rb che serve per creare
 il make file. L'estensione viene creata con devkit, quindi mingw il compilatore g++ sotto windows.
 Le particolarità per compilare il codice come estensione, è stato quella di creare il file RubyTre4AlphaBeta.h
 per l'export di Init_RubyTre4AlphaBeta e quella di avere la libreria lstdc++ linkata (extconf.rb).
 Anche l'ordine degli headers e windows.h vanno settati a modo in mingw. Per quanto riquarda il file
 RubyTre4AlphaBeta.cpp, non sempre gli esempi che si trovano in rete (http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html)
 vanno bene per 1.8.7, quindi bisogna controllare il file ruby.h per essere sicuri.
 Una volta compilata l'estensione col comando make, si lancia irb e poi si mette require 'RubyTre4AlphaBeta',
 include RubyTre4AlphaBeta e puts test1 per vedere se va.



















