require 'sinatra'
require 'httparty'
require 'nokogiri'
require 'date'
require 'time'
require 'json'
require 'tzinfo'
require 'dotenv'
Dotenv.load('token.env')

# Sinatra 서버 설정
set :bind, '0.0.0.0'
set :port, 8080

$commit_counts = []

# GitHub API를 사용하여 커밋 데이터를 가져오는 함수
# since_date와 until_date는 Date 클래스.
def fetch_commit_data(owner, repo, since_str, until_str, page=1)
    url = "https://api.github.com/repos/#{owner}/#{repo}/commits?since=#{since_str}&until=#{until_str}&per_page=100&page=#{page}"
    puts("url : " + url)
    response = HTTParty.get(url, headers: {"User-Agent" => "CommitChart", "Authorization" => "token #{ENV['GITHUB_TOKEN']}"})
    JSON.parse(response.body)
end

def generate_svg(since_str, until_str)
  rect_size = 15
  svg_width = [((($commit_counts.length / 7).floor + 1) * rect_size) + 20, 800].max
  svg_height = 7 * rect_size + 100

  # SVG 시작 태그 및 스타일 정의
  svg = "<svg width='#{svg_width}' height='#{svg_height}' xmlns='http://www.w3.org/2000/svg' style='background-color: #f4f4f4;'>\n"
  svg += "<style>"
  svg += "  rect {"
  svg += "    opacity: 0;"
  svg += "    animation: fadeIn 0.5s ease-in-out forwards;"
  svg += "  }"
  svg += "  @keyframes fadeIn {"
  svg += "    to {"
  svg += "      opacity: 1;"
  svg += "    }"
  svg += "  }"
  svg += "</style>\n"

  # 텍스트 위치 조정
  svg += "<text x='10' y='30' fill='black' font-family='Arial' font-size='14'>since #{since_str}</text>\n"
  svg += "<text x='10' y='50' fill='black' font-family='Arial' font-size='14'>until #{until_str}</text>\n"

  max_count = $commit_counts.max

  # 사각형 및 애니메이션 추가
  $commit_counts.each_with_index do |count, index|
    x = (index / 7).floor * rect_size + 10
    y = (index % 7).floor * rect_size + 70
    level = commit_level(count, max_count)
    color = level_to_color(level)

    delay = index * 0.05
    svg += "<rect x='#{x}' y='#{y}' width='#{rect_size}' height='#{rect_size}' fill='#{color}' stroke='white' stroke-width='1' style='animation-delay:#{delay}s;' />\n"
  end

  svg += "</svg>"
  svg
end

def commit_level(count, max_count)
  # Define levels based on commit count
  case count
  when 0 then 0
  when 1..max_count/4 then 1
  when max_count/4..max_count/4*2 then 2
  when max_count/4*2..max_count/4*3 then 3
  else 4
  end
end

def level_to_color(level)
  # Define color based on level
  case level
  when 0 then '#ebedf0' # No commits
  when 1 then '#9be9a8' # Few commits
  when 2 then '#40c463' # Some commits
  when 3 then '#30a14e' # Many commits
  else '#216e39' # Most commits
  end
end


get '/' do
  "Hello World"
end

def utc_offset_in_hours(timezone_name)
  tz = TZInfo::Timezone.get(timezone_name) rescue TZInfo::Timezone.get("Asia/Seoul")
  current_period = tz.current_period
  offset_seconds = current_period.utc_offset + current_period.std_offset
  offset_hours = offset_seconds / 3600.0

  offset_hours.to_i
end

def config_commit_counts(commit_data, since_date, until_date)
  commit_data.each do |commit|
    commit_date_str = commit["commit"]["committer"]["date"]
    commit_date = DateTime.parse(commit_date_str)

    # since_date와 until_date 범위 내의 날짜만 고려
    if commit_date >= since_date && commit_date <= until_date
      puts("commit_date : #{commit_date.iso8601}, since_date : #{since_date.iso8601}")
      puts "#{(commit_date - since_date).to_i}"
      $commit_counts[(commit_date - since_date).to_i] += 1
    end
  end
end

# 라우트 설정
get '/:owner/:repo' do
    owner = params[:owner]
    puts("owner : " + owner)
    repo = params[:repo]
    puts("repo : " + repo)
    puts("since param : " + (params[:since] || "nil"))
    puts("until param : " + (params[:until] || "nil"))
    since_date = DateTime.parse(params[:since]) rescue DateTime.now() - 365
    until_date = DateTime.parse(params[:until]) rescue DateTime.now() + 1
    timezone_param = params[:tz] || "Asia/Seoul"
    offset_hours = utc_offset_in_hours(timezone_param)
    puts("offset hours : ")
    puts offset_hours
    if until_date < since_date
      since_date = until_date - 365
    end

    since_date = since_date - Rational(offset_hours, 24)
    until_date = until_date - Rational(offset_hours, 24)

    since_str = since_date.strftime('%Y-%m-%dT%H:%M:%SZ')
    puts("since_date : " + since_date.iso8601)
    puts(since_str)
    until_str = until_date.strftime('%Y-%m-%dT%H:%M:%SZ')
    puts(until_str)

    days_difference = (until_date - since_date).to_i
    $commit_counts = Array.new(days_difference, 0)

    [1,2,3,4].each do |page|
      commit_data = fetch_commit_data(owner, repo, since_str, until_str, page)
      config_commit_counts(commit_data, since_date, until_date)
    end

    svg_chart = generate_svg(since_str, until_str)
    # svg_chart = "<svg></svg>"

    content_type 'image/svg+xml'
    svg_chart
end
