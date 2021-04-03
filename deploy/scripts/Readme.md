## Creare il setup per una nuova versione di Cuperativa
Cambiare il codice della cuperativa in questa repository e settare la nuova versione nel file
cuperativa_gui.rb.

In powershell settare ruby:
$env:path = "D:\ruby\ruby_2_3_1\bin;"+$env:path
Ora si lancia in questa directory:
ruby .\build_the_setup.rb

Il risultato viene messo nella :root_deploy settata nel file target_deploy_info.yaml,
vale a dire la D:\PC_Jim_2016\Projects\ruby\Deployed

## Note
Non convertire il file setup_muster.nsi_tm in UTF8 altrimenti gli accenti vanno persi.
Anche con ruby 2.3.1 gli accenti vanno persi, quindi il file si lascia in ANSI.

## Versione 1.0.1
- mettere in target_deploy_info.yaml la directory dove vengono messe tutte le versioni
- Occorre 7zip e nsis installer. Questi path vanno messi in target_deploy_info.yaml
- La versione che si trova in cuperativa_gui.rb, decide i nomi delle directory e dei files zip
- Occorre una pacchetto con ruby
- Lanciare lo script build_the_setup.rb, esso crea il setup.exe in un colpo solo. 

