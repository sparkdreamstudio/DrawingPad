//
//  ProjectBrifeTableViewCell.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class ProjectBrifeTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbNailsImageView: UIImageView!
    @IBOutlet weak var createdTimeLable: UILabel!
    @IBOutlet weak var workingTimeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
