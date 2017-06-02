# This script will takes in the path to the 1095As dir as argument.
# Usage e.g. rail r script/upload_1095_documents_to_s3.rb /Users/doc_store_files/
#
# The 1095A pdf file names include the metadata.
# We iterate over the list of pdfs and do
#   1) extract metadata - person.hbx_id, policy_id, year etc
#   2) Upload pdf to s3
#   3) create Family.TaxDocument object
#
# Sample pdf names
# 000001_HBX_01_173263_20728_IRS1095A_Corrected.pdf
# 000004_HBX_01_e33326643d7f4f5ebd8710bd9e63e836_3318_IRS1095A.pdf
# IRS1095ACorrected_2015_20160407_191298_48387_000013.pdf
# IRS1095A_2015_20160327_154242_46815_000001.pdf

subject = '1095A' # the business-type of documents being uploaded

dir = ARGV[0]

def hbx_id(file_name)
  file_name.split("_")[3]
end

def version_type(file_name)
  if file_name.downcase.include? "corrected"
    'corrected'
  elsif file_name.downcase.include? "void"
    'void'
  else
    'new'
  end
end

# policy_id
def hbx_enrollment_id(file_name)
  file_name.split("_")[4]
end

def year(file_name)
  year_value = file_name.split("_")[2]
  if (2014..2016).include? year_value
    year_value
  else
    2014
  end
end

Dir.glob("#{dir}/**/*").each do |file|
  next if File.directory? file

  begin
    key = Aws::S3Storage.save(file, 'tax-documents')
    person = Person.where(hbx_id: hbx_id(File.basename(file))).first

    if person.nil?
      puts "Could not find person for doc #{File.basename(file)}"
      next
    end

    family = person.primary_family

    if family.nil?
      puts "Could not find primary_family for doc #{File.basename(file)}"
      next
    end

    if family.households.flat_map(&:hbx_enrollments).flat_map(&:hbx_id).include? hbx_enrollment_id(file)
      puts "Could not find hbx_enrollment_id #{hbx_enrollment_id(file)} for doc #{File.basename(file)} primary family #{family.id}"
      next
    end

    content_type = MIME::Types.type_for(File.basename(file)).first.content_type

    family.documents << TaxDocument.new({identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:tax_documents##{key}",
                                         title: File.basename(file), format: content_type, subject: subject,
                                         rights: 'pii_restricted', version_type: version_type(file),
                                         hbx_enrollment_id: hbx_enrollment_id(file),
                                         year: year(file)})
    family.save!
  rescue => e
    puts "Error #{file} #{e.message}"
  end
end