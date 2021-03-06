# Este script fará uma cópia do backup, de sua unidade X: de sua escolha, copiando na rede em \\servidor\compartilhamento 
# Ele verificar o dia da semana, exemplo Monday, Tuesday etc... e criará uma pasta com este dia e a data
#Na próxima semana, ele irá subscrever o arquivo daquele dia exemplo Monday
# Usuário tem que estar no grupo de backup ou ser administrator para ter sucesso ao rodar o comando ou deixar como schedule

#script busca localização, dia, data e semana
clear
$date = get-date -UFormat %Y-%m-%d
$week = ( get-date ).DayOfWeek
$day = get-date 
$share = '\\srv\testando'
$folder = $share + '\'  +$comp + '\' + $week + '\'+ $date + '\' 
$include = 'include'
$log = $folder + $comp + '.log'
 
# Mapeando o compartilhamento
try{
$mapprocess = start -Wait  net -ArgumentList  "use  i: $share " -PassThru  -NoNewWindow
$mapcode = $mapprocess.exitcode 
if ($mapcode  -ne 0 ){
$result = "$result br Computer $comp FAILED to map drive br with error code $mapcode br br"
}}
catch [exception] {
$result = "$result br Computer $comp FAILED to map drive br br"
}
 
#Criando a pasta do backup se não existir
try {
if ( ! (Test-Path  -Path $folder ) ){
New-Item  -Path $folder  -ItemType Directory -ErrorAction Stop
}}
catch [exception] {
$result = "$result br Computer $comp FAILED to create folder br br"
}

# Criando arquivos de logs em .txt e .html

try {
if ( ! (Test-Path  -Path $log ) ){
New-Item  -Path $log   -ItemType File -ErrorAction Stop
}}
catch [exception] 
{
$result = "$result br Computer $comp FAILED to create log file br br"
}
$start = Get-Date
$process = start -Wait  wbadmin.exe -ArgumentList "start backup -backuptarget:$folder -include:E: -quiet" -PassThru -NoNewWindow -RedirectStandardOutput $log
$code = $process.exitcode 
if ($code  -eq 0 ){
$end = Get-Date
$result = "$result backup complete on $comp, user $user br Started: $start br  Ended: $end br br"
$status = "good"
start net -ArgumentList "use i: /delete /Y" -NoNewWindow 
}
else { 
$end = Get-Date
$result= "$result Backup Failed on $comp, br Started: $start br  Ended: $end  br br"
$status = "BAD" }
$loghtmlfile = $log + '.html'
$File = Get-Content $log
$FileLine = @()
Foreach ($Line in $File) {
 $MyObject = New-Object -TypeName PSObject
 Add-Member -InputObject $MyObject -Type NoteProperty -Name backupstatus -Value $Line
 $FileLine += $MyObject
}
$FileLine | ConvertTo-Html -Property backupstatus | Out-File $loghtmlfile
$loghtml = gc $loghtmlfile 
$result = "$result $loghtml"

#Configurando seu e-mail para receber as notificações

$mail = New-Object system.net.Mail.MailMessage 
$mail.From  = "seu-email@domain.com"
$mail.To.add("backup@domain.com")
$mail.Subject = "Backup Script Results $status $comp $date"
$smtp = new-object system.Net.Mail.SmtpClient("smtp.domain.com")
$mail.IsBodyHtml = "True"
$mail.body = $result 
$smtp.send($mail)
