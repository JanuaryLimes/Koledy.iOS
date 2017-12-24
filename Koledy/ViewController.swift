//
//  ViewController.swift
//  Koledy
//
//  Created by Kacper Śledź on 23.12.2017.
//  Copyright © 2017 JanuaryLimes. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredItems = allItems?.filter{ koleda in
                return koleda.nazwa?.lowercased().contains(searchText.lowercased()) ?? false
            }
        } else {
            filteredItems = allItems
        }
        table.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let koledy = filteredItems else {
            return 0
        }
        return koledy.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as UITableViewCell
        if let koledy = filteredItems {
            let koleda = koledy[indexPath.row]
            cell.textLabel!.text = koleda.nazwa
        }
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        searchController.searchBar.setShowsCancelButton(false, animated: true)
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            if let destinationVC = segue.destination as? SingleViewController {
                destinationVC.currentElement = filteredItems?[selectedIndex]
            }
        }
    }
    
    @IBOutlet weak var table: UITableView!
    let assetName = "Data"
    let segueIdentifier = "ShowSingle"
    var listaKoled = [Koleda]()
    var allItems : [Koleda]?
    var filteredItems : [Koleda]?
    var selectedIndex = -1
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        
        let teksty = readBundle(file: assetName)
        listaKoled = readXml(from: teksty)
        allItems = listaKoled
        filteredItems = allItems
        
        table.dataSource = self
        table.delegate = self
        table.keyboardDismissMode = .interactive
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if  searchController.isActive{
            searchController.searchBar.setShowsCancelButton(true, animated: true)
        }
    }
    
    func setupNavBar(){
        navigationController?.navigationBar.prefersLargeTitles = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func readBundle(file:String) -> String
    {
        var res = ""
        if let asset = NSDataAsset(name: file) ,
            let string = String(data:asset.data, encoding: String.Encoding.utf8){
            res = string
        }
        return res
    }
    
    func readXml(from text:String) -> [Koleda] {
        // We can create a parser from a URL, a Stream, or NSData.
        if let data = text.data(using: String.Encoding.utf8) { // Get the NSData
            let xmlParser = XMLParser(data: data)
            let delegate = KoledaXmlParserDelegate() // This is your own delegate - see below
            xmlParser.delegate = delegate
            if xmlParser.parse() {
                return delegate.koledaArray
            }
        }
        
        return [Koleda]()
    }
}

class KoledaXmlParserDelegate: NSObject, XMLParserDelegate {
    var koledaArray: [Koleda] = []
    enum State { case none, nazwa, tekst }
    var state: State = .none
    var nowaKoleda: Koleda? = nil
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch elementName {
        case "koleda" :
            self.nowaKoleda = Koleda()
            self.state = .none
        case "nazwa":
            self.state = .nazwa
        case "tekst":
            self.state = .tekst
        default:
            self.state = .none
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let newPerson = self.nowaKoleda, elementName == "koleda" {
            self.koledaArray.append(newPerson)
            self.nowaKoleda = nil
        }
        self.state = .none
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let _ = self.nowaKoleda else { return }
        switch self.state {
        case .nazwa:
            self.nowaKoleda!.nazwa = "\(self.nowaKoleda!.nazwa ?? "")\(string)"
        case .tekst:
            var trimmed = string
            trimmed.removingRegexMatches(pattern: "[ ]{2,}")
            self.nowaKoleda!.tekst = "\(self.nowaKoleda!.tekst ?? "")\(trimmed)"
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    }
}

class SingleViewController: UIViewController{
    
    var currentElement : Koleda?
    
    @IBOutlet weak var tekst: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.tekst.text = currentElement?.tekst ?? ""
        self.title = currentElement?.nazwa ?? ""
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        self.tekst.setContentOffset(.zero, animated: false)
    }
}

extension String {
    mutating func removingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }
}


