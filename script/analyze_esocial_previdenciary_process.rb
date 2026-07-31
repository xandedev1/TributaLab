require_relative "../config/environment"
require "json"

paths = ARGV
abort "Uso: ruby script/analyze_esocial_previdenciary_process.rb ARQUIVO_OU_DIRETORIO [...]" if paths.empty?

result = Esocial::PrevidenciaryProcessAnalyzer.new(paths).call

processes = result.processes.map do |process|
	process.to_h.merge(suspensions: process.suspensions.map(&:to_h))
end

rubric_links = result.rubric_links.map(&:to_h)
matches = result.matches.map do |match|
	{
		rubric_link: match.rubric_link.to_h,
		processes: match.processes.map do |process|
			process.to_h.merge(suspensions: process.suspensions.map(&:to_h))
		end
	}
end

lotation_matches = result.lotation_matches.map do |match|
	{
		lotation_link: match.lotation_link.to_h,
		processes: match.processes.map do |process|
			process.to_h.merge(suspensions: process.suspensions.map(&:to_h))
		end
	}
end

puts JSON.pretty_generate(
	processes: processes,
	rubric_links: rubric_links,
	matches: matches,
	unmatched_links: result.unmatched_links.map(&:to_h),
	lotation_links: result.lotation_links.map(&:to_h),
	lotation_matches: lotation_matches,
	unmatched_lotation_links: result.unmatched_lotation_links.map(&:to_h),
	errors: result.errors
)