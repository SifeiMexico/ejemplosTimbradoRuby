#Requiere isntalar la gema savon

#gem install savon
#gem install iniparse
#gem install rubyzip
require 'json'
require 'savon'
require 'iniparse'
require 'time'
require "base64"
require 'zip'

config=IniParse.parse( File.read('config.ini') )

print config
print "hel"

usuario=config['timbrado']['UsuarioSIFEI']
password=config['timbrado']['PasswordSIFEI']
idEquipo=config['timbrado']['IdEquipoGenerado']
usuario=config['timbrado']['UsuarioSIFEI']

#file=File.open('xml_sellado.xml','r');
#cfdi_contenido=file.read
cfdi_contenido=File.read('assets/xml_sellado.xml')

#savon 2 no ofrece una manera directa de acceder al request por lo que deberas de utilizar algun interceptor
client = Savon.client(wsdl: 'http://devcfdi.sifei.com.mx:8080/SIFEI33/SIFEI?wsdl',
    #log: true
    convert_request_keys_to: :none,
    open_timeout: 300,
    read_timeout: 300,
    )
#print client.operations
begin
    #Establecemos el hash(dictionario) con los datos a utilizar!
    soapParams= { 
        Usuario: usuario,
        Password:password ,
        IdEquipo: idEquipo,
        archivoXMLZip: Base64.strict_encode64(cfdi_contenido), # 
        Serie:"" ,
    }
    
    #print soapParams
    #simulamos request para guardarlo y ver como se envia(omitir en produccion)
    operation=client.operation(:get_cfdi)
    request= operation.build(message:soapParams).pretty
    timestamp=Time.now.to_i.to_s    
    File.open("timbrado_request_#{timestamp}.xml" ,"w"){ |file|file.puts request}
    response = client.call(:get_cfdi, message:soapParams)
    # print response.to_xml
    File.open("timbrado_response_#{timestamp}.xml" ,"w"){ |file|file.puts response.to_xml}
    puts "Escribiendo zip"
    zipName="zip_timbrado_#{timestamp}.zip"
    #se decodifica el resultado de la respuesta(base64) y se escribe a un archivo zip que contiene el xml timbrado
    File.open(zipName ,"w"){ |file|file.puts Base64.strict_decode64(response.body[:get_cfdi_response][:return])}


    #una vez escrito el zip, debemos extraer el XML timbrado
    Zip::File.open(zipName) do |zipfile|
        zipfile.each do |file|
          # do something with file
          file.extract
        end
      end
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
 