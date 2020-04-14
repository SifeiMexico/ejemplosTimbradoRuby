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
usuario=config['timbrado']['UsuarioSIFEI']

#file=File.open('xml_sellado.xml','r');
#cfdi_contenido=file.read
cfdi_contenido=File.read('xml_sellado.xml')

#savon 2 no ofrece una manera directa de acceder al request por lo que deberas de utilizar algun interceptor
client = Savon.client(wsdl: 'http://devcfdi.sifei.com.mx:8080/SIFEI33/SIFEI?wsdl',
    #log: true
    )
#print client.operations
begin
    #Establecemos el hash(dictionario) con los datos a utilizar!
    soapParams= { 
        Usuario: usuario,
        Password:password ,
        IdEquipo: idEquipo,
        archivoXMLZip: Base64.encode64(cfdi_contenido), # 
        Serie:"" ,
    }
    
    print soapParams
    #simulamos 
    operation=client.operation(:get_cfdi)
    request= operation.build(message:soapParams).pretty
    timestamp=Time.now.to_i.to_s    
    File.open("timbrado_request_#{timestamp}.xml" ,"w"){ |file|file.puts request}
    response = client.call(:get_cfdi, message:soapParams)
    # print response.to_xml
    File.open("timbrado_response_#{timestamp}.xml" ,"w"){ |file|file.puts response.to_xml}
rescue Savon::SOAPFault => e  
    #print client.request
    puts "Exception:"
    puts e.message    
    puts e.http.code    
    puts e.to_hash#[':fault']#[':faultcode']    
    File.open("timbrado_response_#{timestamp}.xml" ,"w"){ |file|file.puts e.http.body}

   # print e.backtrace
    
    #print e.as_json
end
 