//
//  KoledaXmlParser.swift
//  Koledy
//
//  Created by Kacper Śledź on 24.12.2017.
//  Copyright © 2017 JanuaryLimes. All rights reserved.
//

import Foundation

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
