//
//  ViewController.swift
//  Koledy
//
//  Created by Kacper Śledź on 23.12.2017.
//  Copyright © 2017 JanuaryLimes. All rights reserved.
// 

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listaKoled.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "\(listaKoled[indexPath.row].nazwa ?? "")"
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            if let destinationVC = segue.destination as? SingleViewController {
                destinationVC.currentElement = listaKoled[selectedIndex]
            }
        }
    }
    
    @IBOutlet weak var table: UITableView!
    let assetName = "Data"
    let segueIdentifier = "ShowSingle"
    var listaKoled = [Koleda]()
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let teksty = readBundle(file: assetName)
        listaKoled = readXml(from: teksty)
        
        table.dataSource = self
        table.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @IBAction func backClicked(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBOutlet weak var tekst: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //currentElement?.tekst?.removingRegexMatches(pattern: "[ ]{2,}")
        
        tekst.isEditable = false
        tekst.isSelectable = false
        tekst.text = currentElement?.tekst ?? ""
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


