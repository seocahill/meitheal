namespace :pages do
  desc "Seed Irish (ga) versions of pages from the old NCF site"
  task seed_irish: :environment do
    irish_pages = [
      {
        slug: "about",
        title: "Maidir le THENCF",
        visibility: :published,
        nav_location: :footer,
        content: <<~HTML
          <div class="mx-auto max-w-7xl py-12 px-4 sm:px-6 lg:flex lg:items-center lg:justify-between lg:py-16 lg:px-8">
            <article class="prose lg:prose-xl">
              <h2>Maidir le THENCF</h2>
              <p>Is comhoibríocht chultúrtha í THENCF í. Tá muid lonnaithe i mBéal Átha an Fheadha, Contae Mhaigh Eo agus tá muid eagraithe de réir na <a href="https://www.ica.coop/en/whats-co-op/co-operative-identity-values-principles">prionsabail chomhoibre ICA</a>.</p>
              <h3>Spriocanna</h3>
              <ul>
                <li>Cruinnithe pobail agus sóisialta do ealaíontóirí áitiúla.</li>
                <li>Spásanna poiblí agus príobháideacha do ealaíontóirí.</li>
                <li>Laghdú ar imirce óige ón cheantar trí áiseanna sóisialta níos fearr.</li>
                <li>Méadú páirtíochta sna healaíona.</li>
                <li>Forbairt ealaíontóirí áitiúla.</li>
                <li>Athghiniúint an bhaile trí spásanna folamha a athúsáid.</li>
                <li>Cothú oícheanta beo, fíorúil, nua-aimseartha sa cheantar.</li>
                <li>Feabhsú clú agus cáil an cheantair thar lear.</li>
              </ul>
              <h3>Coiste na Gaeilge</h3>
              <ul>
                <li>Seosamh Ó Cathail (rúnaí)</li>
                <li>Sharon Ní Chuilibín</li>
                <li>Darren Ó Ríagáin</li>
                <li>Brídín Ní Gabhann</li>
              </ul>
              <h3>Comhairleoirí</h3>
              <ul>
                <li>Paul Cunningham, Stúirthóir Ionad Éalaíne BÁF</li>
                <li>Anne-Marie Flynn, Turasóireacht Maigh Eo Thuaidh</li>
                <li>Pádraic S. Ó Murchú, Turas Siar</li>
                <li>Peter Dooley, Cuntasóirí Cahill Trautt</li>
              </ul>
            </article>
          </div>
        HTML
      },
      {
        slug: "proposal",
        title: "Forógra",
        visibility: :published,
        nav_location: :hidden,
        content: <<~HTML
          <div class="mx-auto max-w-7xl py-12 px-4 sm:px-6 lg:flex lg:items-center lg:justify-between lg:py-16 lg:px-8">
            <article class="prose lg:prose-xl">
              <h2>Forógra</h2>
              <h3>An Teangaidh Dhúchais sa gCeantar</h3>
              <p>"Ghrá thú!" nó "Bhuel boc!" a deir muintir Bhéal Átha an Fheadha de ghnás, nuair a chasann siad ar a chéile. Ní haon iontas é, mar bhí An Ghaeilge le cluins go mion minic ar na sráideanna go dtí tuairim is céad bliain ó shin agus tá píosa maith fághta sa leagan Béarla a bhíos ann sa bhaile inniú.</p>
              <p>Sin ráite, bíonn sé doiligh corruair, áiteanna cearta sa mbaile a bhaint amach agus daoine ag iarraidh Gaeilge a labhairt lena chéile gan stró. Is ábhar spéisúil é, ach cuireann an Gaeilge isteach ar an mBéarlóir go minic agus neart ól tógtha aige ag an am. Sin rud amháin go dtiocfadh linn a chur i gceart, áras na Gaeilge a chur ar bun i measc na n-imeachtaí eile.</p>
              <p>Tá baint domhain, nadúrach, láidir idir an Ghaeilge agus an ealaín. Tigeann na mílte daoine chun na teangadh i dtoiseach, tríd an gceol mar shampla, agus tá meas mór ag lucht an chultúir, ar an nGaeilge. Bheadh sé cuí agus cóir an dá ábhar a chur i dtoll a chéile, go h-áirithe os rud é go bhfuil an t–úafás scéalta, filíochta, amhráin agus stair áitiúil ann agus iad dearmadaithe ag na daoine mar níl a dteanga dhúchais acu a thuilleadh. Bheadh an meitheal ealaíne bealach amháin, ár n-oidhreacht a athbheochan sa gceantar.</p>
              <h3>Insporáid</h3>
              <h4>Ionad beag</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/EeI8GVvDD4Y" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
              <h4>Caife snascheoil</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/Ot3gkTzxkb4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
              <h4>Club búitíc</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/EzKp87PogNs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
              <h4>Spás Éalaine meánmhéide</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/0x1zenp86VE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
              <h4>Spás Éalaine Mór</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/Ac31UuTnn0c" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
              <h4>Féile na Spilt Milk</h4>
              <iframe class="w-full aspect-video" src="https://www.youtube.com/embed/wMnyrJ6CS5I" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
            </article>
          </div>
        HTML
      },
      {
        slug: "space",
        title: "An Spás",
        visibility: :published,
        nav_location: :hidden,
        content: <<~HTML
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-4xl font-bold mb-6">An Spás</h1>
            <p class="text-gray-600 mb-8">Dearc ar an bhféilire thíos agus líon amach an fhoirm chun an spás a chur in áirithe. Tabhair faoi deara go bhfuil íosmhéid €20 ag teastáil le haghaidh costais roinnte in aghaidh an lae. Tá gach áirithint sealadach go dtí go ndeimhnítear trí ríomhphost é. Níl an spás ar fáil ach do bhaill amháin.</p>
          </div>
        HTML
      },
      {
        slug: "thanks",
        title: "Go Raibh Maith Agat",
        visibility: :published,
        nav_location: :hidden,
        content: <<~HTML
          <div class="mx-auto max-w-7xl py-12 px-4 sm:px-6 lg:flex lg:items-center lg:justify-between lg:py-16 lg:px-8">
            <article class="prose lg:prose-xl">
              <h2>GRMA!</h2>
              <p>Beidh muid i dteagmháil leat.</p>
            </article>
          </div>
        HTML
      }
    ]

    irish_pages.each do |attrs|
      page = Page.find_or_initialize_by(slug: attrs[:slug], locale: "ga")
      page.assign_attributes(
        title: attrs[:title],
        visibility: attrs[:visibility],
        nav_location: attrs[:nav_location],
        content: attrs[:content]
      )
      if page.save
        puts "#{page.persisted? ? "Updated" : "Created"}: /ga/#{page.slug} — #{page.title}"
      else
        puts "Failed #{page.slug}: #{page.errors.full_messages.join(", ")}"
      end
    end

    puts "Done."
  end
end
