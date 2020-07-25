require 'net/http'
require 'uri'
require 'json'

# 기본 경로 설정
home_dir = File.expand_path '~/.dandy'

# 선택 문장 가져오기
query_file = File.join home_dir, 'query'
query = File.read query_file

crlf = /(\r\n|\n\r|\r|\n)/
query = query.gsub(crlf, "\r\n")

# 부산대 맞춤법/문법 검사기 접속
uri = URI.parse 'http://speller.cs.pusan.ac.kr/results'

http = Net::HTTP.new uri.host, uri.port

request = Net::HTTP::Post.new uri.request_uri
request.set_form_data 'text1' => query

begin
    response = http.request request

    # 필요한 데이터만 뽑아 내기
    if response.body =~ /\s*data = \[(.*)\];/im
        source = $1
        data = JSON.parse(source)
        count = data['errInfo'].length
    else
        source = "HTML 분석에 실패했습니다."
        count = 0
    end
rescue => e
    source = e
    count = 0
end

# 설정 파일 읽기
config_file = File.join home_dir, 'config'
config = File.read config_file

# 템플릿 파일 읽기
template_file = File.join home_dir, 'template'
template = File.read template_file

result = ''
if count != 0
  data['errInfo'].each do |item|
    result += "<table id='tableErr_#{item['errorIdx']}' class='tableErrCorrect' border='1' cellpadding='3' cellspacing='0'>\n"
    result += "  <!--틀린어절 -->\n"
    result += "  <TR>\n"
    result += "    <TD class='tdLT' title=0>입력 내용</TD>\n"
    result += "    <TD id='tdErrorWord_0' class='tdErrWord' style='color:#FF0000;' >#{item['orgStr']}</TD>\n"
    result += "  </TR>\n"
    result += "  <!--대치어 -->\n"
    result += "  <TR>\n"
    result += "    <TD class='tdLT'>대치어</TD>\n"
    result += "    <TD id='tdReplaceWord_0' class='tdReplace' >#{item['candWord'].split('|').join('<br/>')}</TD>\n"
    result += "  </TR>\n"
    result += "  <!--도움말 -->\n"
    result += "  <TR>\n"
    result += "    <TD class='tdLT'>도움말</TD>\n"
    result += "    <TD id='tdHelp_0' class='tdETNor'><br/>#{item['help']}</TD>\n"
    result += "  </TR>\n"
    result += "</TABLE><br/>\n"
  end
end

# 템플릿 채우기
template.gsub!('{{count}}') {count.to_s.force_encoding('utf-8')}
template.gsub!('{{result}}') {result.force_encoding('utf-8')}
template.gsub!('{{config}}') {config.force_encoding('utf-8')}

# 최종 결과 파일에 쓰기
output_file = File.join home_dir, 'dandy.html'
File.open(output_file, 'w') do |file|
    file.write template
end
