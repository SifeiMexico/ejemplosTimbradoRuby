#Requiere isntalar la gema savon

#gem install savon
#gem install iniparse
require 'json'
require 'savon'
require 'iniparse'
require 'time'
require "base64"

config=IniParse.parse( File.read('config.ini') )

print config
print "hel"

usuario=config['timbrado']['UsuarioSIFEI']
password=config['timbrado']['PasswordSIFEI']
idEquipo=config['timbrado']['IdEquipoGenerado']
pfxPath=config['timbrado']['PFX']

#file=File.open('xml_sellado.xml','r');
#cfdi_contenido=file.read
pfx=File.read(pfxPath)

#savon 2 no ofrece una manera directa de acceder al request por lo que deberas de utilizar algun interceptor
client = Savon.client(wsdl: 'http://devcfdi.sifei.com.mx:8888/CancelacionSIFEI/Cancelacion?wsdl',
    #log: true
    )
    passwordPfx ="a0123456789"
#print client.operations
begin
    #Establecemos el hash(dictionario) con los datos a utilizar!
    soapParams= { 
        usuarioSIFEI: usuario,
        passwordSifei:password ,
        rfcEmisor: idEquipo,
        pfx: Base64.encode64(pfx), # PFX CONFORMADO POR key y cert
        passwordPfx: passwordPfx, #         
        uuids:'uuids'
    }
    
    print soapParams
    #simulamos 
    operation=client.operation(:cancela_cfdi)
    request= operation.build(message:soapParams).pretty
    timestamp=Time.now.to_i.to_s    
    File.open("cancelacion_request_#{timestamp}.xml" ,"w"){ |file|file.puts request}
    response = client.call(:cancela_cfdi, message:soapParams)
    # print response.to_xml
    File.open("cancelacion_response_#{timestamp}.xml" ,"w"){ |file|file.puts response.to_xml}
    puts "Acuse"
    #puts response.body
    puts response.body[:cancela_cfdi_response][:return];
    File.open("cancelacion_acuse_#{timestamp}.xml" ,"w"){ |file|file.puts response.body[:cancela_cfdi_response][:return]}

rescue Savon::SOAPFault => e  
    #print client.request
    puts "Exception:"
    puts e.message    
    puts e.http.code    
    puts e.to_hash#[':fault']#[':faultcode']    
    File.open("cancelacion_response_#{timestamp}.xml" ,"w"){ |file|file.puts e.http.body}

   # print e.backtrace
    
    #print e.as_json
end
 