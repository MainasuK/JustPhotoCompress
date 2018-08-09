//
//  ActionOptionTableViewController.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2018-8-2.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit

protocol ActionOptionTableViewModel {
    var title: String { get }
    func numberOfOptions() -> Int
    func option(at indexPath: IndexPath) -> String
    func select(at indexPath: IndexPath)
}

protocol ActionSizeOptionTableViewModelDelegate: class {
    func didSelect(option: PhotoCompressor.Size)
}

class ActionSizeOptionTableViewModel: ActionOptionTableViewModel {

    weak var delegate: ActionSizeOptionTableViewModelDelegate?

    let optionType = PhotoCompressor.Size.self
    let title = NSLocalizedString("Size", comment: "")

    var options: [PhotoCompressor.Size] = [
        PhotoCompressor.Size.large,
        PhotoCompressor.Size.medium,
        PhotoCompressor.Size.small
    ]

    func numberOfOptions() -> Int {
        return options.count
    }

    func option(at indexPath: IndexPath) -> String {
        return options[indexPath.row].string
    }

    func select(at indexPath: IndexPath) {
        delegate?.didSelect(option: options[indexPath.row])
    }

}

protocol ActionQualityOptionTableViewModelDelegate: class {
    func didSelect(option: PhotoCompressor.Quality)
}

class ActionQualityOptionTableViewModel: ActionOptionTableViewModel {

    weak var delegate: ActionQualityOptionTableViewModelDelegate?

    let title = NSLocalizedString("Quality", comment: "")

    var options: [PhotoCompressor.Quality] = [
        PhotoCompressor.Quality.great,
        PhotoCompressor.Quality.good,
        PhotoCompressor.Quality.normal
    ]

    func numberOfOptions() -> Int {
        return options.count
    }

    func option(at indexPath: IndexPath) -> String {
        return options[indexPath.row].string
    }

    func select(at indexPath: IndexPath) {
        delegate?.didSelect(option: options[indexPath.row])
    }

}

final class ActionOptionTableViewController: UITableViewController {

    var viewModel: ActionOptionTableViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfOptions()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCellStyleValue1") ??
            UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "UITableViewCellStyleValue1")

        cell.textLabel?.text = viewModel.option(at: indexPath)
        cell.accessoryType   = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.select(at: indexPath)
        navigationController?.popViewController(animated: true)
    }

}
