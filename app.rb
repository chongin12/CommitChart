require 'sinatra'
require 'httparty'
require 'nokogiri'
require 'date'
require 'time'
require 'json'
require 'tzinfo'

# Sinatra 서버 설정
set :bind, '0.0.0.0'
set :port, 8080

# GitHub API를 사용하여 커밋 데이터를 가져오는 함수
# since_date와 until_date는 Date 클래스.
def fetch_commit_data(owner, repo, since_str, until_str)
    url = "https://api.github.com/repos/#{owner}/#{repo}/commits?since=#{since_str}&until=#{until_str}"
    puts("url" + url)
    response = HTTParty.get(url, headers: {"User-Agent" => "CommitChart"})
    JSON.parse(response.body)
end


def generate_svg(commit_data, since_str, until_str)
  # 간단한 SVG 시작 태그
  svg = "<svg width='800' height='100' xmlns='http://www.w3.org/2000/svg'>\n"

  # since, until 텍스트 추가
  svg += "<text x='10' y='40' fill='white'>since
	#{since_str}</text>\n"
  svg += "<text x='10' y='60' fill='white'>until #{until_str}</text>\n"

  # "잔디" 그리기
  start_date = Date.parse(since_str)
  end_date = Date.parse(until_str)
  commit_counts = commit_data[:commit_counts] # This should be a hash where keys are dates and values are commit counts

  (start_date..end_date).each_with_index do |date, index|
    x = (index % 53) * 14 + 10 # 53 weeks, 14px per "잔디" plus some margin
    y = (index / 53).floor * 14 + 80 # New row every 53 "잔디"
    level = commit_level(commit_counts[date] || 0)
    color = level_to_color(level)

    svg += "<rect x='#{x}' y='#{y}' width='10' height='10' fill='#{color}' />\n"
  end

  # SVG 닫기
  svg += "</svg>"
  svg
end

def commit_level(count)
  # Define levels based on commit count
  case count
  when 0 then 0
  when 1..4 then 1
  when 5..9 then 2
  when 10..19 then 3
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

# 커밋 데이터 예시 (key는 날짜, value는 그 날의 커밋 횟수를 나타냄)
commit_counts = {
    Date.new(2024, 1, 1) => 1,
    Date.new(2024, 1, 2) => 2,
    # ... 중간 날짜 데이터 ...
    Date.new(2024, 1, 30) => 1,
    Date.new(2024, 1, 31) => 0, # 커밋 없음
    Date.new(2024, 2, 1) => 1,
    # ... 중간 날짜 데이터 ...
    Date.new(2024, 2, 28) => 1,
}

def config_level_color
  max_value = commit_counts.max()
  # TODO
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

def config_commit_data(commit_data, since_date, until_date)
  commit_data.each do |commit|
    commit_date_str = commit["commit"]["committer"]["date"]
    commit_date = DateTime.parse(commit_date_str)

    # since_date와 until_date 범위 내의 날짜만 고려
    if commit_date >= since_date && commit_date <= until_date
      puts "#{(commit_date - since_date).to_i}"
      commit_counts[(commit_date - since_date).to_i] += 1
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

    since_date = since_date.new_offset(Rational(-offset_hours, 24))
    until_date = until_date.new_offset(Rational(-offset_hours, 24))

    since_str = since_date.strftime('%Y-%m-%dT%H:%M:%SZ')
    puts(since_str)
    until_str = until_date.strftime('%Y-%m-%dT%H:%M:%SZ')
    puts(until_str)

    days_difference = (until_date - since_date).to_i
    commit_counts = Array.new(days_difference, 0)

    commit_data = fetch_commit_data(owner, repo, since_date, until_date)
    config_commit_data(commit_data, since_date, until_date)
    config_level_color()

    # svg_chart = generate_svg(commit_data, since_str, until_str)
    svg_chart = "<svg></svg>"

    content_type 'image/svg+xml'
    svg_chart
end
