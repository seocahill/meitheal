class RefreshFundingOpportunitiesJob < ApplicationJob
  queue_as :default

  def perform
    return unless llm_configured?

    Rails.logger.info("Starting funding opportunities refresh...")

    begin
      response = chat.ask(prompt)
      opportunities = parse_response(response.content)

      created_count = 0
      updated_count = 0
      skipped_count = 0

      opportunities.each do |opp_data|
        result = create_or_update_opportunity(opp_data)
        case result
        when :created then created_count += 1
        when :updated then updated_count += 1
        when :skipped then skipped_count += 1
        end
      end

      Rails.logger.info("Funding opportunities refresh complete: #{created_count} created, #{updated_count} updated, #{skipped_count} skipped")
    rescue => e
      Rails.logger.error("Funding opportunities refresh failed: #{e.message}")
      raise
    end
  end

  private

  def llm_configured?
    RubyLLM.config.mistral_api_key.present?
  end

  def chat
    @chat ||= RubyLLM.chat(model: "mistral-small-latest")
  end

  def prompt
    <<~PROMPT
      You are a funding research assistant for an arts cooperative in Mayo, Ireland. Search your knowledge for current and upcoming funding opportunities from these sources:

      **Mayo Arts Service (Mayo County Council)**
      - Mayo Artist Bursary, Arts Act Grants, Tyrone Guthrie Bursary, Upstart Awards, Drama League of Ireland Summer School Bursary, Creative Mayo Grant Scheme, Per Cent for Art Scheme, Public Art Panel, Partnership Funding, Platform 31

      **Local & Community Funding**
      - LEADER Programme, SICAP, CLÁR Programme, Community Enhancement Programme, Municipal District Funding/GMA

      **National Bodies**
      - The Arts Council of Ireland (Bursary Awards, Project Awards, Agility Award, Artist in the Community Scheme)
      - Culture Ireland (Regular Grants Programme)
      - Creative Ireland Programme (Creative Climate Action Fund)

      **European**
      - Creative Europe (Culture Strand, MEDIA Strand, Cross-sectoral Strand)

      Return ONLY a valid JSON array of funding opportunities. Each opportunity must have:
      - title: string (the grant/scheme name)
      - organization: string (the funding body)
      - description: string (brief description of the grant)
      - amount: integer (funding amount in EUR, or null if variable/unspecified)
      - deadline: string (ISO date format YYYY-MM-DD, or estimate if rolling deadline)
      - categories: string (comma-separated: e.g., "visual arts,performance,community")
      - url: string (official website URL, or null if unavailable)

      Format your response as valid JSON only, no additional text:
      [{"title": "...", "organization": "...", ...}, ...]

      Include at least 10-15 opportunities with realistic deadlines spread throughout the year. Focus on currently open or upcoming opportunities.
    PROMPT
  end

  def parse_response(response_text)
    # Extract JSON from response (handle cases where LLM adds text before/after)
    json_match = response_text.match(/\[.*\]/m)
    return [] unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse LLM response as JSON: #{e.message}")
    []
  end

  def create_or_update_opportunity(data)
    # Idempotent: find by title + organization + deadline
    existing = FundingOpportunity.find_by(
      title: data["title"],
      organization: data["organization"],
      deadline: Date.parse(data["deadline"])
    )

    if existing
      # Update if description or other fields changed
      if existing.description != data["description"] ||
         existing.amount != data["amount"] ||
         existing.url != data["url"] ||
         existing.categories != data["categories"]
        existing.update!(
          description: data["description"],
          amount: data["amount"],
          url: data["url"],
          categories: data["categories"]
        )
        :updated
      else
        :skipped
      end
    else
      # Create new opportunity (unapproved by default)
      FundingOpportunity.create!(
        title: data["title"],
        organization: data["organization"],
        description: data["description"],
        amount: data["amount"],
        deadline: Date.parse(data["deadline"]),
        categories: data["categories"],
        url: data["url"],
        approved: false
      )
      :created
    end
  rescue => e
    Rails.logger.error("Failed to create/update opportunity #{data['title']}: #{e.message}")
    :skipped
  end
end
