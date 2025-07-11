# 🧠 whoisgit

`whoisgit` is a minimal reimplementation of Git in Ruby — designed to **learn**, **teach**, and **visualize** how Git really works under the hood.

🔧 CLI Command: `iamgit`  
🎨 Visual Frontend: React + D3.js  
🚀 Backend API: Sinatra

---

## 🧱 What It Does

This project re-creates core Git functionality from scratch using Ruby, including:

- `init`: Create a Git-like repository (`.mygit/`)
- `hash-object`: Store file contents as Git blobs
- `cat-file`: Inspect raw Git objects
- `write-tree`: Snapshot file structure
- `commit`: Commit changes with history
- `log`: View commit history
- And more...

But unlike Git, this project also **visualizes** every operation with a web UI powered by **React + D3.js**. You can see objects being created, commits being added to the DAG, and how Git stores your work internally.

---

## 🧪 Getting Started

### 1. Clone & Install

```bash
git clone https://github.com/yourname/whoisgit.git
cd whoisgit
bundle install
npm install --prefix frontend
```

### 2. Run the CLI

```bash
./bin/iamgit init
./bin/iamgit hash-object README.md
./bin/iamgit commit -m "First commit"
```

### 3. Start the Visual Server

```bash
ruby backend/app.rb
```

Then open your browser at [http://localhost:4567](http://localhost:4567) to explore the internals visually.

---

## 📦 Project Structure

```
whoisgit/
├── bin/iamgit          # CLI entry point
├── backend/            # Sinatra + Git logic in Ruby
│   └── lib/
├── frontend/           # React + D3.js visualization
│   └── src/
├── .mygit/             # Git-like object store (created by init)
```

---

## 🧩 Tech Stack

- **CLI**: Ruby 
- **Git internals**: Ruby
- **Web server/API**: Sinatra
- **Frontend**: React + D3.js

---

## 🧠 Why?

Git is famously hard to understand. This project makes it transparent by:

- Rebuilding it piece-by-piece
- Using code that’s readable and educational
- Pairing every command with a **visual explanation**

Ideal for:

- Students learning Git internals
- Devs who want to go deeper
- Educators looking for a teaching tool

---

## ✅ Roadmap

- [x] `init` command + visual folder tree
- [x] `hash-object` command + blob storage animation
- [x] `cat-file` to inspect raw content
- [ ] `commit` → visual DAG node
- [ ] `log` → visualize history
- [ ] `branch`, `checkout`, `merge`
- [ ] Visual diffs between commits

---

## 📝 License

MIT — do what you want, but give credit where credit is due.

---

## 🤝 Contributing

This project is focused on learning and teaching. If you’d like to contribute improvements, ideas, or visuals, PRs are welcome.

---

> Built with ❤️ and a lot of SHA-1 by someone asking: *who is git, really?*